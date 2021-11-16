// Copyright (c) DataStax, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"context"
	"flag"
	"strings"
	"time"

	"github.com/datastax/cql-proxy/proxy"
	"github.com/datastax/cql-proxy/proxycore"

	"github.com/datastax/go-cassandra-native-protocol/primitive"
	"github.com/go-ping/ping"
	"go.uber.org/zap"
)

func main() {
	// get cassandra endpoints
	hosts := flag.String("hosts", "", "list of cassandra hosts, comma separated")

	flag.Parse()

	endpoints := strings.Split(*hosts, ",")
	if len(endpoints) == 0 {
		panic("no cassandra hosts provided")
	}

	curr := endpoints[0]

	logger, err := zap.NewProduction()
	if err != nil {
		panic(err)
	}

	p := proxy.NewProxy(context.Background(), proxy.Config{
		Version:         primitive.ProtocolVersion4,
		Resolver:        proxycore.NewResolver(curr),
		ReconnectPolicy: proxycore.NewReconnectPolicy(),
		NumConns:        1,
		Logger:          logger,
	})

	go func() {
		err = p.ListenAndServe(":9042")
		if err != nil {
			logger.Error(err.Error())
		}
	}()

	// every second
	for {
		time.Sleep(10 * time.Second)
		best := curr
		// max int
		bestLatency := int(^uint(0) >> 1)

		// ping all endpoints
		for _, endpoint := range endpoints {
			pinger, err := ping.NewPinger(endpoint)
			if err != nil {
				logger.Error(err.Error())
				continue
			}

			pinger.SetPrivileged(true)
			pinger.Count = 3

			err = pinger.Run() // Blocks until finished.
			if err != nil {
				logger.Error(err.Error())
				continue
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

		p.Shutdown()

		p = proxy.NewProxy(context.Background(), proxy.Config{
			Version:         primitive.ProtocolVersion4,
			Resolver:        proxycore.NewResolver(best),
			ReconnectPolicy: proxycore.NewReconnectPolicy(),
			NumConns:        1,
			Logger:          logger,
		})

		go func() {
			err = p.ListenAndServe(":9042")
			if err != nil {
				logger.Error(err.Error())
			}
		}()

		curr = best
	}
}
