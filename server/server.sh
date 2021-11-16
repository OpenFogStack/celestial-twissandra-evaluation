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
# configure and run cassandra proxy
sleep 30
echo "ls /"
ls -la /
echo "ls"
ls
echo "pwd"
pwd

ping cass1.gst.celestial -c 2
ping 10.255.0.10 -c 2
while ! nc -z "10.255.0.10" "9042" ; do echo "cannot reach cass1.gst.celestial:9042" ; sleep 1 ; done

./cql_proxy.bin --hosts=cass1.gst.celestial &
export CASSANDRA_HOST="localhost"
sleep 10
cd twissandra
gunicorn -k egg:meinheld#gunicorn_worker -c "./gunicorn_conf.py"  "twissandra.wsgi:application"
cd /
cd rom/twissandra
gunicorn -k egg:meinheld#gunicorn_worker -c "./gunicorn_conf.py" "twissandra.wsgi:application"
cd /
cat twissandra/wsgi.py