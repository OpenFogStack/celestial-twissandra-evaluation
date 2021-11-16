#!/bin/sh

#
# This file is part of Celestial's Twissandra Evaluation
# (https://github.com/OpenFogStack/celestial-twissandra-evaluation).
# Copyright (c) 2021 Tobias Pfandzelter, The OpenFogStack Team.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

GATEWAY_IP=$(/sbin/ip route | awk '/default/ { print $2 }')
IP=$(/sbin/ip route | awk 'FNR==2{ print $7 }')

echo nameserver "$GATEWAY_IP" > /etc/resolv.conf
export CASSANDRA_CONF=/apache-cassandra-2.2.19/conf
export CASSANDRA_CONFIG="$CASSANDRA_CONF"
#export CASSANDRA_SEEDS=cassandraEU
export CASSANDRA_CLUSTER_NAME=mycluster
export CASSANDRA_DC=AS
export CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
export CASSANDRA_LISTEN_ADDRESS="$IP"

echo "IP: $IP"
/sbin/ip route

set -e

: ${CASSANDRA_RPC_ADDRESS='0.0.0.0'}

: ${CASSANDRA_LISTEN_ADDRESS='auto'}
if [ "$CASSANDRA_LISTEN_ADDRESS" = 'auto' ]; then
    CASSANDRA_LISTEN_ADDRESS="$(hostname --ip-address)"
fi

: ${CASSANDRA_BROADCAST_ADDRESS="$CASSANDRA_LISTEN_ADDRESS"}

if [ "$CASSANDRA_BROADCAST_ADDRESS" = 'auto' ]; then
    CASSANDRA_BROADCAST_ADDRESS="$(hostname --ip-address)"
fi
: ${CASSANDRA_BROADCAST_RPC_ADDRESS:=$CASSANDRA_BROADCAST_ADDRESS}

if [ -n "${CASSANDRA_NAME:+1}" ]; then
    : ${CASSANDRA_SEEDS:="cassandra"}
fi
: ${CASSANDRA_SEEDS:="$CASSANDRA_BROADCAST_ADDRESS"}

sed -ri 's/(- seeds:).*/\1 "'"$CASSANDRA_SEEDS"'"/' "$CASSANDRA_CONFIG/cassandra.yaml"

sed -ri 's/^(# )?('"broadcast_address"':).*/\2 '"$CASSANDRA_BROADCAST_ADDRESS"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
sed -ri 's/^(# )?('"broadcast_rpc_address"':).*/\2 '"$CASSANDRA_BROADCAST_RPC_ADDRESS"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
sed -ri 's/^(# )?('"cluster_name"':).*/\2 '"$CASSANDRA_CLUSTER_NAME"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
sed -ri 's/^(# )?('"endpoint_snitch"':).*/\2 '"$CASSANDRA_ENDPOINT_SNITCH"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
sed -ri 's/^(# )?('"listen_address"':).*/\2 '"$CASSANDRA_LISTEN_ADDRESS"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
# sed -ri 's/^(# )?('"num_tokens"':).*/\2 '"$CASSANDRA_NUM_TOKENS"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
sed -ri 's/^(# )?('"rpc_address"':).*/\2 '"$CASSANDRA_RPC_ADDRESS"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
# sed -ri 's/^(# )?('"start_rpc"':).*/\2 '"$CASSANDRA_START_RPC"'/' "$CASSANDRA_CONFIG/cassandra.yaml"


sed -ri 's/^('"dc"'=).*/\1 '"$CASSANDRA_DC"'/' "$CASSANDRA_CONFIG/cassandra-rackdc.properties"
#sed -ri 's/^('"rack"'=).*/\1 '"$CASSANDRA_RACK"'/' "$CASSANDRA_CONFIG/cassandra-rackdc.properties"

cd apache-cassandra-2.2.19/bin
./cassandra -f