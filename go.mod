module github.com/OpenFogStack/celestial-twissandra-evaluation

go 1.17

replace github.com/datastax/cql-proxy => ./server/cql-proxy

require (
	github.com/datastax/cql-proxy v0.0.0-00010101000000-000000000000
	github.com/datastax/go-cassandra-native-protocol v0.0.0-20210604174339-4311e5d5654d
	github.com/go-ping/ping v0.0.0-20211014180314-6e2b003bffdd
	go.uber.org/zap v1.17.0
)

require (
	github.com/antlr/antlr4/runtime/Go/antlr v0.0.0-20210521184019-c5ad59b459ec // indirect
	github.com/google/uuid v1.2.0 // indirect
	github.com/hashicorp/golang-lru v0.5.4 // indirect
	go.uber.org/atomic v1.8.0 // indirect
	go.uber.org/multierr v1.7.0 // indirect
	golang.org/x/net v0.0.0-20210405180319-a5a99cb37ef4 // indirect
	golang.org/x/sync v0.0.0-20210220032951-036812b2e83c // indirect
	golang.org/x/sys v0.0.0-20210510120138-977fb7262007 // indirect
)
