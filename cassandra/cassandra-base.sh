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
apk add --no-cache openjdk8-jre gnupg python2 python3 wget tar
wget https://archive.apache.org/dist/cassandra/2.2.19/apache-cassandra-2.2.19-bin.tar.gz
tar -xvzf apache-cassandra-2.2.19-bin.tar.gz
mv /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/jli/libjli.so /lib
java -version
/usr/lib/jvm/default-jvm/jre/bin/java -version