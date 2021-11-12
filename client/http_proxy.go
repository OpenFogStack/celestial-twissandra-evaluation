// Author: WU Yong (yowu)
// https://gist.github.com/yowu/f7dc34bd4736a65ff28d
package main

import (
	"flag"
	"io"
	"log"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/go-ping/ping"
)

// Hop-by-hop headers. These are removed when sent to the backend.
// http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html
var hopHeaders = []string{
	"Connection",
	"Keep-Alive",
	"Proxy-Authenticate",
	"Proxy-Authorization",
	"Te", // canonicalized version of "TE"
	"Trailers",
	"Transfer-Encoding",
	"Upgrade",
}

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

func delHopHeaders(header http.Header) {
	for _, h := range hopHeaders {
		header.Del(h)
	}
}

func appendHostToXForwardHeader(header http.Header, host string) {
	// If we aren't the first proxy retain prior
	// X-Forwarded-For information as a comma+space
	// separated list and fold multiple headers into one.
	if prior, ok := header["X-Forwarded-For"]; ok {
		host = strings.Join(prior, ", ") + ", " + host
	}
	header.Set("X-Forwarded-For", host)
}

type proxy struct {
	host string
}

func (p *proxy) ServeHTTP(wr http.ResponseWriter, req *http.Request) {
	log.Println(req.RemoteAddr, " ", req.Method, " ", req.URL)

	if req.URL.Scheme != "http" {
		msg := "unsupported protocal scheme " + req.URL.Scheme
		http.Error(wr, msg, http.StatusBadRequest)
		log.Println(msg)
		return
	}

	client := &http.Client{}

	//http: Request.RequestURI can't be set in client requests.
	//http://golang.org/src/pkg/net/http/client.go
	req.RequestURI = ""
	req.URL.Host = p.host

	delHopHeaders(req.Header)

	if clientIP, _, err := net.SplitHostPort(req.RemoteAddr); err == nil {
		appendHostToXForwardHeader(req.Header, clientIP)
	}

	resp, err := client.Do(req)
	if err != nil {
		http.Error(wr, "Server Error", http.StatusInternalServerError)
		log.Fatal("ServeHTTP:", err)
	}
	defer resp.Body.Close()

	log.Println(req.RemoteAddr, " ", resp.Status)

	delHopHeaders(resp.Header)

	copyHeader(wr.Header(), resp.Header)
	wr.WriteHeader(resp.StatusCode)
	io.Copy(wr, resp.Body)
}

func main() {
	// get list of hosts from command line
	// ping every host and return the first one that responds
	// if that host is different than the current one, switch the proxy to that host
	// repeat that every second

	// get twissandra endpoints
	hosts := flag.String("hosts", "", "list of twissandra hosts, comma separated")

	endpoints := strings.Split(*hosts, ",")
	if len(endpoints) == 0 {
		panic("no twissandra hosts provided")
	}

	curr := endpoints[0]

	s := &http.Server{
		Addr: ":80", Handler: &proxy{host: curr},
	}

	go func() {
		err := s.ListenAndServe()
		if err != nil {
			panic(err)
		}
	}()

	// every second
	for {
		time.Sleep(1 * time.Second)
		best := curr
		// max int
		bestLatency := int(^uint(0) >> 1)

		// ping all endpoints
		for _, endpoint := range endpoints {
			pinger, err := ping.NewPinger(endpoint)
			if err != nil {
				panic(err)
			}

			pinger.SetPrivileged(true)
			pinger.Count = 3

			err = pinger.Run() // Blocks until finished.
			if err != nil {
				panic(err)
			}

			rtt := pinger.Statistics().AvgRtt.Nanoseconds() // get send/receive/duplicate/rtt stats

			if rtt < int64(bestLatency) {
				bestLatency = int(rtt)
				best = endpoint
			}
		}

		// if the one with the best performance is not the current one, switch to it
		if best == curr {
			continue
		}

		s.Close()

		s = &http.Server{
			Addr: ":80", Handler: &proxy{host: best},
		}

		go func() {
			err := s.ListenAndServe()
			if err != nil {
				panic(err)
			}
		}()

		curr = best
	}
}
