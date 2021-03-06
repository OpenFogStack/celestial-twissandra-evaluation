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

IP=$(/sbin/ip route | awk '/default/ { print $3 }')

echo nameserver "$IP" > /etc/resolv.conf

ulimit -n
ulimit -Hn
ulimit -Sn

ulimit -n 64000

ulimit -n
ulimit -Hn
ulimit -Sn

# configure and run twissandra proxy
chmod +x tcp_proxy.bin
cd /
#./tcp_proxy.bin --selection=ping --ping-hosts=tw1.gst.celestial &
./tcp_proxy.bin --selection=api --api-endpoint="$IP" &
export TWISSANDRA_HOST="localhost"
export TWISSANDRA_PORT="80"

while ! nc -w 5 -z "$TWISSANDRA_HOST" "$TWISSANDRA_PORT" ; do
    echo "cannot reach $TWISSANDRA_HOST:$TWISSANDRA_PORT"
    sleep 5
done

while ! curl -m 5 http://"$TWISSANDRA_HOST":"$TWISSANDRA_PORT" ; do
    echo "cannot curl $TWISSANDRA_HOST:$TWISSANDRA_PORT"
    sleep 5
done

locust --csv-full-history --headless --csv=/stats--headless --users 1 -H http://"$TWISSANDRA_HOST":"$TWISSANDRA_PORT"