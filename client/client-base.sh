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
apk add --no-cache gcc g++ libc-dev libffi-dev make curl
apk add --no-cache python3
apk add --no-cache python3-dev
apk add --no-cache py3-pip
python3 -m pip install --no-cache-dir wheel
python3 -m pip install pyzmq-22.3.0-cp39-cp39-linux_x86_64.whl
rm pyzmq-22.3.0-cp39-cp39-linux_x86_64.whl
python3 -m pip install Brotli-1.0.9-cp39-cp39-linux_x86_64.whl
rm Brotli-1.0.9-cp39-cp39-linux_x86_64.whl
python3 -m pip install gevent-21.8.0-cp39-cp39-linux_x86_64.whl
rm gevent-21.8.0-cp39-cp39-linux_x86_64.whl
python3 -m pip install --no-cache-dir pyzmq==22.3.0
python3 -m pip install --no-cache-dir locust==2.4.1 beautifulsoup4==4.10.0 python-lorem==1.1.2

mkdir -p /etc/security
echo "*    soft nofile 64000" > /etc/security/limits.conf
echo "*    hard nofile 64000" >> /etc/security/limits.conf
echo "root soft nofile 64000" >> /etc/security/limits.conf
echo "root hard nofile 64000" >> /etc/security/limits.conf

echo "fs.file-max = 64000" >> /etc/sysctl.conf

mkdir -p stats