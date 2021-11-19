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

.PHONY: all

all: client/client.img server/server.img cassandra/cassandra.img combinedcloud/combinedcloud.img combinedsat/combinedsat.img

client/tcp_proxy.bin: client/tcp_proxy.go
	CGOENABLED=0 GOOS=linux GOARCH=amd64 go build -o client/tcp_proxy.bin client/tcp_proxy.go

client/client.img: client/client.sh client/client-base.sh client/tcp_proxy.bin twissandra/benchmark/locustfile.py
	@docker run --rm -v $(PWD)/client/client.sh:/app.sh -v $(PWD)/client/client-base.sh:/base.sh -v $(PWD)/client/tcp_proxy.bin:/files/tcp_proxy.bin -v $(PWD)/twissandra/benchmark/locustfile.py:/files/locustfile.py -v $(PWD)/wheels/pyzmq-22.3.0-cp39-cp39-linux_x86_64.whl:/files/pyzmq-22.3.0-cp39-cp39-linux_x86_64.whl -v $(PWD)/wheels/gevent-21.8.0-cp39-cp39-linux_x86_64.whl:/files/gevent-21.8.0-cp39-cp39-linux_x86_64.whl -v $(PWD)/wheels/Brotli-1.0.9-cp39-cp39-linux_x86_64.whl:/files/Brotli-1.0.9-cp39-cp39-linux_x86_64.whl -v $(PWD)/client/tcp_proxy.bin:/files/tcp_proxy.bin -v $(PWD):/opt/code --privileged rootfsbuilder $@

cassandra/cassandra.img: cassandra/cassandra.sh cassandra/cassandra-base.sh
	@docker run --rm -v $(PWD)/cassandra/cassandra.sh:/app.sh -v $(PWD)/cassandra/cassandra-base.sh:/base.sh -v $(PWD)/cassandra/init.cqlsh:/files/init.cqlsh -v $(PWD):/opt/code --privileged rootfsbuilder $@

server/cql_proxy.bin: server/cql_proxy.go
	CGOENABLED=0 GOOS=linux GOARCH=amd64 go build -o server/cql_proxy.bin server/cql_proxy.go

server/server.img: server/server.sh server/cql_proxy.bin server/server-base.sh server/gunicorn_conf.py twissandra/twissandra twissandra/__init__.py twissandra/manage.py twissandra/twissandra
	@docker run --rm -v $(PWD)/server/server.sh:/app.sh -v $(PWD)/server/server-base.sh:/base.sh -v $(PWD)/server/cql_proxy.bin:/files/cql_proxy.bin -v $(PWD)/server/gunicorn_conf.py:/files/twissandra/gunicorn_conf.py -v $(PWD)/twissandra/__init__.py:/files/twissandra/__init__.py -v $(PWD)/twissandra/manage.py:/files/twissandra/manage.py -v $(PWD)/twissandra/twissandra:/files/twissandra/twissandra -v $(PWD)/wheels/cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl:/files/cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl -v $(PWD):/opt/code --privileged rootfsbuilder $@

combinedcloud/combinedcloud.img: combinedcloud/combinedcloud.sh combinedcloud/combinedcloud-base.sh
	@docker run --rm -v $(PWD)/combinedcloud/combinedcloud.sh:/app.sh -v $(PWD)/combinedcloud/combinedcloud-base.sh:/base.sh -v $(PWD)/server/gunicorn_conf.py:/files/twissandra/gunicorn_conf.py -v $(PWD)/twissandra/__init__.py:/files/twissandra/__init__.py -v $(PWD)/twissandra/manage.py:/files/twissandra/manage.py -v $(PWD)/twissandra/twissandra:/files/twissandra/twissandra -v $(PWD)/wheels/cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl:/files/cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl -v $(PWD)/cassandra/init.cqlsh:/files/init.cqlsh -v $(PWD)/cassandra/join.cqlsh:/files/join.cqlsh -v $(PWD):/opt/code --privileged rootfsbuilder $@

combinedsat/id_finder.bin: combinedsat/id_finder.go
	CGOENABLED=0 GOOS=linux GOARCH=amd64 go build -o combinedsat/id_finder.bin combinedsat/id_finder.go

combinedsat/cass_finder.bin: combinedsat/cass_finder.go
	CGOENABLED=0 GOOS=linux GOARCH=amd64 go build -o combinedsat/cass_finder.bin combinedsat/cass_finder.go

combinedsat/combinedsat.img: combinedsat/combinedsat.sh combinedsat/combinedsat-base.sh combinedsat/id_finder.bin combinedsat/cass_finder.bin
	@docker run --rm -v $(PWD)/combinedsat/combinedsat.sh:/app.sh -v $(PWD)/combinedsat/combinedsat-base.sh:/base.sh -v $(PWD)/server/gunicorn_conf.py:/files/twissandra/gunicorn_conf.py -v $(PWD)/twissandra/__init__.py:/files/twissandra/__init__.py -v $(PWD)/twissandra/manage.py:/files/twissandra/manage.py -v $(PWD)/twissandra/twissandra:/files/twissandra/twissandra -v $(PWD)/wheels/cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl:/files/cassandra_driver-3.6.0-cp39-cp39-linux_x86_64.whl -v $(PWD)/cassandra/init.cqlsh:/files/init.cqlsh -v $(PWD)/combinedsat/id_finder.bin:/files/id_finder.bin -v $(PWD)/combinedsat/cass_finder.bin:/files/cass_finder.bin -v $(PWD):/opt/code --privileged rootfsbuilder $@