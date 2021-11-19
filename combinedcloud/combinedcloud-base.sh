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

apk update
apk add --no-cache gcc libc-dev
apk add --no-cache python3
apk add --no-cache python3-dev
apk add --no-cache py3-pip
python3 -m pip install --no-cache-dir  wheel
python3 -m pip install --no-cache-dir meinheld==1.0.2 gunicorn==20.1.0
python3 -m pip install cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl
rm cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl
python3 -m pip install --no-cache-dir Django==1.11.29 python-lorem==1.1.2 pytz==2021.3 simplejson==3.17.5 tqdm==4.62.3 beautifulsoup4==4.10.0
apk add --no-cache openjdk8-jre gnupg python2 python3 wget tar
wget https://archive.apache.org/dist/cassandra/2.2.19/apache-cassandra-2.2.19-bin.tar.gz
tar -xvzf apache-cassandra-2.2.19-bin.tar.gz
mv /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/jli/libjli.so /lib
java -version
/usr/lib/jvm/default-jvm/jre/bin/java -version
rm apache-cassandra-2.2.19-bin.tar.gz
echo 'rc_controller_cgroups="YES"' >> /etc/rc.conf
echo 'rc_cgroup_mode="legacy"' >> /etc/rc.conf
echo "cgroup /sys/fs/cgroup cgroup defaults 0 0" >> /etc/fstab
# cat >> /etc/cgconfig.conf <<EOF
# mount {
# cpuacct = /cgroup/cpuacct;
# memory = /cgroup/memory;
# devices = /cgroup/devices;
# freezer = /cgroup/freezer;
# net_cls = /cgroup/net_cls;
# blkio = /cgroup/blkio;
# cpuset = /cgroup/cpuset;
# cpu = /cgroup/cpu;
# }
# EOF