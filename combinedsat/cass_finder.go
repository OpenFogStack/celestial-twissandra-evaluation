package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/go-ping/ping"
)

func main() {
	// get cassandra endpoints
	hosts := flag.String("hosts", "", "list of cassandra hosts, comma separated")

	flag.Parse()

	endpoints := strings.Split(*hosts, ",")
	if len(endpoints) == 0 {
		panic("no cassandra hosts provided")
	}

	best := endpoints[0]

	// max int
	bestLatency := int(^uint(0) >> 1)

	// ping all endpoints
	for _, endpoint := range endpoints {
		fmt.Printf("testing %s\n", endpoint)
		pinger, err := ping.NewPinger(endpoint)
		if err != nil {
			fmt.Printf("error creating pinger: %s", err.Error())
			continue
		}

		pinger.Timeout = 3 * time.Second
		pinger.SetPrivileged(true)
		pinger.Count = 3

		err = pinger.Run() // Blocks until finished.
		if err != nil {
			fmt.Printf("error running pinger: %s", err.Error())
			continue
		}

		rtt := pinger.Statistics().AvgRtt.Nanoseconds() // get send/receive/duplicate/rtt stats

		if rtt < int64(bestLatency) {
			bestLatency = int(rtt)
			best = endpoint
		}
	}

	fmt.Printf("best endpoint: %s\n", best)

	f, err := os.Create("cass.txt")

	if err != nil {
		log.Fatalf("could not open seeds.txt: %s", err.Error())
	}

	fmt.Fprint(f, best)
	f.Close()
}
