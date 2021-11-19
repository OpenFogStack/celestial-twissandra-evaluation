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

sleep 5
GATEWAY_IP=$(/sbin/ip route | awk '/default/ { print $3 }')
IP=$(/sbin/ip route | awk 'FNR==2{ print $7 }')

/sbin/ip route
echo "GATEWAY: $GATEWAY_IP"
echo "IP: $IP"

echo nameserver "$GATEWAY_IP" > /etc/resolv.conf

cd /

echo "ls -l /"
ls -l /
echo "ls -l /sys/fs/cgroup"
ls -l /sys/fs/cgroup
#ls -l /sys/fs/cgroup/cpu_and_mem

echo "cat /proc/mounts"


echo "mount cgroup hierarchy"
mount -t tmpfs cgroup_root /sys/fs/cgroup
echo "mkdir cpu_and_mem"
mkdir /sys/fs/cgroup/cpu_and_mem
echo "mount cpu_and_mem"
mount -t cgroup -o cpuset,memory cpu_and_mem /sys/fs/cgroup/cpu_and_mem
echo "cat /proc/mounts"
cat /proc/mounts

cd /

# get the id
./id_finder.bin --api-host="$GATEWAY_IP"
# check if id.txt exists
if [ -f id.txt ]; then
    # if it exists, read the id
    # if we are a cassandra node, do cassandra stuff
    # if not, skip
    ID=$(cat id.txt)

    echo "CASSANDRA ID: CASS$ID"
    export CASSANDRA_DC=CASS"$ID"

    if [ "$ID" = "0" ]; then
        # we are the seed node!
        echo "We are the seed node!"

    else
        # we are not the seed node!
        export CASSANDRA_SEEDS="0.0.celestial"
        echo "Cassandra seed: $CASSANDRA_SEEDS"
        until nc -z "$CASSANDRA_SEEDS" "9160"
        do
            echo "waiting for cassandra seed to start"
            sleep 1
        done
    fi

    export CASSANDRA_CONF=/apache-cassandra-2.2.19/conf
    export CASSANDRA_CONFIG="$CASSANDRA_CONF"
    export CASSANDRA_CLUSTER_NAME=mycluster
    export CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch
    export CASSANDRA_LISTEN_ADDRESS="$IP"

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
    ulimit -n 64000

    #cgcreate -g cpuset,memory:/cassandra_group
    echo "mkdir /sys/fs/cgroup/cpu_and_mem/cassandra_group"
    mkdir /sys/fs/cgroup/cpu_and_mem/cassandra_group
    #cgset -r cpuset.cpus=0,2 cassandra_group
    echo "echo 0,2 > /sys/fs/cgroup/cpu_and_mem/cassandra_group/cpuset.cpus"
    echo 0,2 > /sys/fs/cgroup/cpu_and_mem/cassandra_group/cpuset.cpus
    #cgset -r memory.limit_in_bytes=2G cassandra_group
    echo "echo 2G > /sys/fs/cgroup/cpu_and_mem/cassandra_group/memory.limit_in_bytes"
    echo 2G > /sys/fs/cgroup/cpu_and_mem/cassandra_group/memory.limit_in_bytes
    echo "echo 0 > /sys/fs/cgroup/cpu_and_mem/cassandra_group/cpuset.mems"
    echo 0 > /sys/fs/cgroup/cpu_and_mem/cassandra_group/cpuset.mems
    #cgexec -g cpuset:cassandra_group ./cassandra
    echo "Starting cassandra"
    cd apache-cassandra-2.2.19/bin
    # sh -c "echo -n \$$ > /sys/fs/cgroup/cpu_and_mem/cassandra_group/tasks && ./cassandra -f" &
    ./cassandra -p /sys/fs/cgroup/cpu_and_mem/cassandra_group/tasks
    cat /sys/fs/cgroup/cpu_and_mem/cassandra_group/tasks

    while ! nc -z "localhost" "9042" ; do echo "cannot reach localhost:9042" ; sleep 1 ; done
    sleep 5

    if [ "$ID" = "0" ]; then
        # we are the seed node!
        echo "Seed creating keyspace..."
        ./cqlsh --file=/init.cqlsh
    else
        # we are not the seed node!
        echo "Seed joining cluster..."
    fi
fi

# END CASSANDRA STUFF
# START TWISSANDRA STUFF

while ! curl -m 5 http://"$GATEWAY_IP"/shell/0 ; do
    echo "cannot curl http://$GATEWAY_IP/shell/0"
    sleep 5
done

cd /
sleep 10
./cass_finder.bin --hosts=0.0.celestial,10.0.celestial,20.0.celestial,30.0.celestial,175.0.celestial,185.0.celestial,195.0.celestial,340.0.celestial,350.0.celestial,360.0.celestial,370.0.celestial,515.0.celestial,525.0.celestial,535.0.celestial,680.0.celestial,690.0.celestial,700.0.celestial,710.0.celestial,855.0.celestial,865.0.celestial,875.0.celestial,1020.0.celestial,1030.0.celestial,1040.0.celestial,1050.0.celestial

CASSANDRA_HOST="$(cat cass.txt)"
while ! nc -z "$CASSANDRA_HOST" "9042" ; do echo "cannot reach $CASSANDRA_HOST:9042" ; sleep 1 ; done
sleep 5
export CASSANDRA_HOST
echo "will use cassandra host $CASSANDRA_HOST"
cd twissandra

# cql select selects the best cassandra node

#cgcreate -g cpuset,memory:/twissandra_group
echo "mkdir /sys/fs/cgroup/cpu_and_mem/twissandra_group"
mkdir /sys/fs/cgroup/cpu_and_mem/twissandra_group
#cgset -r cpuset.cpus=1 twissandra_group
echo "echo 1 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.cpus"
echo 1 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.cpus
#cgset -r memory.limit_in_bytes=512M twissandra_group
echo "echo 512M > /sys/fs/cgroup/cpu_and_mem/twissandra_group/memory.limit_in_bytes"
echo 512M > /sys/fs/cgroup/cpu_and_mem/twissandra_group/memory.limit_in_bytes
echo "echo 0 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.mems"
echo 0 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.mems

echo "moving self $$ to twissandra cgroup"
echo $$ > /sys/fs/cgroup/cpu_and_mem/twissandra_group/tasks
#export CORES=8
while true ; do
    gunicorn -k egg:meinheld#gunicorn_worker -c "./gunicorn_conf.py"  "twissandra.wsgi:application" || true
done