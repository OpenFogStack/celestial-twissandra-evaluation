// Author: WU Yong (yowu)
// https://gist.github.com/yowu/f7dc34bd4736a65ff28d
package main

import (
	"flag"
	"io"
	"log"
	"net"
	"strings"
	"time"

	"github.com/go-ping/ping"
)

func copy(closer chan struct{}, dst io.Writer, src io.Reader) {
	_, _ = io.Copy(dst, src)
	closer <- struct{}{} // connection is closed, send signal to stop proxy
}

type proxy struct {
	host string
}

func (p *proxy) serve(close <-chan struct{}) {
	listener, err := net.Listen("tcp", ":80")

	if err != nil {
		panic(err)
	}

	go func(){
		<-close
		listener.Close()
	}()

	for {
		conn, err := listener.Accept()
		log.Println("New connection", conn.RemoteAddr())
		if err != nil {
			log.Println("error accepting connection", err)
			continue
		}
		go func() {
			defer conn.Close()
			conn2, err := net.Dial("tcp", p.host)
			if err != nil {
				log.Println("error dialing remote addr", err)
				return
			}
			defer conn2.Close()
			closer := make(chan struct{}, 2)
			go copy(closer, conn2, conn)
			go copy(closer, conn, conn2)
			<-closer
			log.Println("Connection complete", conn.RemoteAddr())
		}()
	}
}

func main() {
	// get list of hosts from command line
	// ping every host and return the first one that responds
	// if that host is different than the current one, switch the proxy to that host
	// repeat that every second

	// get twissandra endpoints
	hosts := flag.String("hosts", "", "list of twissandra hosts, comma separated")

	flag.Parse()

	endpoints := strings.Split(*hosts, ",")
	if len(endpoints) == 0 {
		panic("no twissandra hosts provided")
	}

	curr := endpoints[0]

	p := &proxy{host: curr}

	close := make(chan struct{})

	go func() {
		p.serve(close)
	}()

	// every ten seconds
	for {
		time.Sleep(10 * time.Second)
		best := curr
		// max int
		bestLatency := int(^uint(0) >> 1)

		// ping all endpoints
		for _, endpoint := range endpoints {
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

		// if the one with the best performance is not the current one, switch to it
		if best == curr {
			continue
		}

		close <- struct{}{}

		p = &proxy{host: best}

		go func() {
			p.serve(close)
		}()

		curr = best
	}
}
