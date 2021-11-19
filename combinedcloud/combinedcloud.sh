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

GATEWAY_IP=$(/sbin/ip route | awk '/default/ { print $3 }')
IP=$(/sbin/ip route | awk 'FNR==2{ print $7 }')


echo "IP: $IP"
/sbin/ip route



echo nameserver "$GATEWAY_IP" > /etc/resolv.conf
export CASSANDRA_CONF=/apache-cassandra-2.2.19/conf
export CASSANDRA_CONFIG="$CASSANDRA_CONF"
export CASSANDRA_CLUSTER_NAME=mycluster
export CASSANDRA_DC=CASS1
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

# cat /etc/rc.conf

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
#cgcreate -g cpuset,memory:/cassandra_group
echo "mkdir /sys/fs/cgroup/cpu_and_mem/cassandra_group"
mkdir /sys/fs/cgroup/cpu_and_mem/cassandra_group
#cgset -r cpuset.cpus=0,2,4,6,8,10,12,14 cassandra_group
echo "echo 0,2,4,6,8,10,12,14 > /sys/fs/cgroup/cpu_and_mem/cassandra_group/cpuset.cpus"
echo 0,2,4,6,8,10,12,14 > /sys/fs/cgroup/cpu_and_mem/cassandra_group/cpuset.cpus
#cgset -r memory.limit_in_bytes=8G cassandra_group
echo "echo 8G > /sys/fs/cgroup/cpu_and_mem/cassandra_group/memory.limit_in_bytes"
echo 8G > /sys/fs/cgroup/cpu_and_mem/cassandra_group/memory.limit_in_bytes
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

./cqlsh --file=/init.cqlsh

cd /

export CASSANDRA_HOST="localhost"
sleep 10
cd twissandra

#cgcreate -g cpuset,memory:/twissandra_group
echo "mkdir /sys/fs/cgroup/cpu_and_mem/twissandra_group"
mkdir /sys/fs/cgroup/cpu_and_mem/twissandra_group
#cgset -r cpuset.cpus=1,3,5,7,9,11,13,15 twissandra_group
echo "echo 1,3,5,7,9,11,13,15 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.cpus"
echo 1,3,5,7,9,11,13,15 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.cpus
#cgset -r memory.limit_in_bytes=8G twissandra_group
echo "echo 8G > /sys/fs/cgroup/cpu_and_mem/twissandra_group/memory.limit_in_bytes"
echo 8G > /sys/fs/cgroup/cpu_and_mem/twissandra_group/memory.limit_in_bytes
echo "echo 0 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.mems"
echo 0 > /sys/fs/cgroup/cpu_and_mem/twissandra_group/cpuset.mems

echo "moving self $$ to twissandra cgroup"
echo $$ > /sys/fs/cgroup/cpu_and_mem/twissandra_group/tasks
#export CORES=8
while true ; do
    gunicorn -k egg:meinheld#gunicorn_worker -c "./gunicorn_conf.py"  "twissandra.wsgi:application"
done