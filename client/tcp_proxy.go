// Author: WU Yong (yowu)
// https://gist.github.com/yowu/f7dc34bd4736a65ff28d
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/go-ping/ping"
)

const (
	pingMethod = iota
	apiMethod
)

type proxy struct {
	host string
}

func (p *proxy) serve(newConns <-chan net.Conn, close <-chan struct{}) {
	for {
		select {
		case conn := <-newConns:
			defer conn.Close()

			log.Println("connecting", conn.RemoteAddr(), "to remote", p.host)
			conn2, err := net.Dial("tcp", p.host)

			if err != nil {
				log.Println("error dialing remote addr", err)
				continue
			}

			defer conn2.Close()
			go io.Copy(conn2, conn)
			go io.Copy(conn, conn2)
		case <-close:
			log.Println("proxy: closing")
			return
		}
	}
}

func selectHostPing(hosts []string) string {
	if len(hosts) == 0 {
		return ""
	}

	if len(hosts) == 1 {
		return hosts[0]
	}

	best := hosts[0]

	// max int
	bestLatency := int(^uint(0) >> 1)

	// ping all endpoints
	for _, endpoint := range hosts {
		pinger, err := ping.NewPinger(endpoint)
		if err != nil {
			log.Printf("couldn't create pinger: %s", err.Error())
		}

		pinger.SetPrivileged(true)
		pinger.Count = 3

		err = pinger.Run() // Blocks until finished.
		if err != nil {
			log.Printf("couldn't start pinger: %s", err.Error())
		}

		rtt := pinger.Statistics().AvgRtt.Nanoseconds() // get send/receive/duplicate/rtt stats

		if rtt < int64(bestLatency) {
			bestLatency = int(rtt)
			best = endpoint
		}
	}

	return best
}

func selectHostAPI(apiEndpoint string, id string) string {
	url := fmt.Sprintf("http://%s/gst/%s", apiEndpoint, id)
	resp, err := http.Get(url)
	if err != nil {
		log.Printf("couldn't get %s: %s", url, err.Error())
		return ""
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Printf("couldn't read response body: %s", err.Error())
		return ""
	}

	// what we got was not a json!
	// continue
	if !strings.HasPrefix(string(body), "{") {
		log.Printf("got response: %s (not a json)\n", string(body))
		return ""
	}

	type Sat struct {
		Sat int
		Shell int
	}

	type SatInfo struct {
		Sat Sat
		Delay float64
	}

	type Info struct {
		ConnectedSats []SatInfo
	}

	i := Info{}

	err = json.Unmarshal(body, &i)
	if err != nil {
		log.Printf("couldn't unmarshal body (%s): %s", string(body), err.Error())
		return ""
	}

	resp.Body.Close()

	if len(i.ConnectedSats) == 0 {
		log.Printf("no connected satellites (body %s)", string(body))
		return ""
	}

	best := i.ConnectedSats[0]
	for _, sat := range i.ConnectedSats {
		if sat.Delay < best.Delay {
			best = sat
		}
	}

	log.Printf("best satellite %d %d selected from %s %+v\n", best.Sat.Sat, best.Sat.Shell, string(body), i.ConnectedSats)

	return fmt.Sprintf("%d.%d.celestial", best.Sat.Sat, best.Sat.Shell)
}

func main() {
	// get list of hosts from command line
	// ping every host and return the first one that responds
	// if that host is different than the current one, switch the proxy to that host
	// repeat that every second

	// get twissandra endpoints
	selection := flag.String("selection", "ping", "selection method for host to proxy to")
	pinghosts := flag.String("ping-hosts", "", "list of twissandra hosts to ping, comma separated")
	apiEndpoint := flag.String("api-endpoint", "", "celestial api endpoint")
	flag.Parse()

	var selectionMethod int
	var pingEndpoints []string
	var identifier string

	if *selection == "ping" {
		selectionMethod = pingMethod
		pingEndpoints = strings.Split(*pinghosts, ",")
		if len(pingEndpoints) == 0 {
			panic("no twissandra hosts provided")
		}
	} else if *selection == "api" {
		selectionMethod = apiMethod
		if len(*apiEndpoint) == 0 {
			panic("no api endpoint provided")
		}

		// get identifier by calling api endpoint /self
		// we have to do wait for the api to be ready
		for {
			url := fmt.Sprintf("http://%s/self", *apiEndpoint)
			resp, err := http.Get(url)
			if err != nil {
				log.Println("couldn't get url", err.Error())
				continue
			}

			body, err := ioutil.ReadAll(resp.Body)
			if err != nil {
				log.Println("couldn't read body", err.Error())
				continue
			}

			resp.Body.Close()

			// what we got was not a json!
			// continue
			if !strings.HasPrefix(string(body), "{") {
				log.Printf("got response: %s (waiting)\n", string(body))
				time.Sleep(3 * time.Second)
				continue
			}

			id := struct{
				Name string
			}{}
			err = json.Unmarshal(body, &id)
			if err != nil {
				fmt.Println("couldn't parse json", err.Error(), string(body))
				continue
			}

			identifier = id.Name


			if identifier == "" {
				log.Println("couldn't get identifier from api endpoint")
				continue
			}

			log.Println("identifier:", identifier)
			break
		}

	} else {
		log.Fatalf("invalid selection method: %s", *selection)
	}

	close := make(chan struct{})

	var curr string
	var p *proxy

	log.Println("proxy: starting listener on :80")
	listener, err := net.Listen("tcp", ":80")

	if err != nil {
		panic(err)
	}

	defer listener.Close()

	newConns := make(chan net.Conn)

	go func() {
		log.Println("proxy: accepting connections")
		for {
			conn, err := listener.Accept()
			if err != nil {
				log.Println("error accepting connection", err)
				return
			}

			log.Println("proxy: new connection from", conn.RemoteAddr())
			newConns <- conn
		}
	}()

	// every ten seconds
	for {
		best := curr
		log.Println("selecting host")
		switch selectionMethod {
		case pingMethod:
			best = selectHostPing(pingEndpoints)
		case apiMethod:
			best = selectHostAPI(*apiEndpoint, identifier)
		}

		// if the one with the best performance is not the current one, switch to it
		if best == curr || best == "" {
			time.Sleep(10 * time.Second)
			log.Println("no new best host")
			continue
		}

		log.Println("found new best host:", best)
		if p != nil {
			log.Println("closing old proxy")
			close <- struct{}{}
		}

		log.Println("starting new proxy")
		p = &proxy{host: fmt.Sprintf("%s:80", best)}

		go func() {
			log.Println("starting proxy serve")
			p.serve(newConns, close)
		}()

		curr = best
		time.Sleep(10 * time.Second)
	}
}
