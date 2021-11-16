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

all: client/client.img server/server.img cassandra/cassandra.img combined/combined.img

client/tcp_proxy.bin: client/tcp_proxy.go
	CGOENABLED=0 GOOS=linux GOARCH=amd64 go build -o client/tcp_proxy.bin client/tcp_proxy.go

client/client.img: client/client.sh client/client-base.sh client/tcp_proxy.bin twissandra/benchmark/locustfile.py
	@docker run --rm -v $(PWD)/client/client.sh:/app.sh -v $(PWD)/client/client-base.sh:/base.sh -v $(PWD)/client/tcp_proxy.bin:/files/tcp_proxy.bin -v $(PWD)/twissandra/benchmark/locustfile.py:/files/locustfile.py -v $(PWD):/opt/code --privileged rootfsbuilder $@

cassandra/cassandra.img: cassandra/cassandra.sh cassandra/cassandra-base.sh
	@docker run --rm -v $(PWD)/cassandra/cassandra.sh:/app.sh -v $(PWD)/cassandra/cassandra-base.sh:/base.sh -v $(PWD):/opt/code --privileged rootfsbuilder $@

server/cql_proxy.bin: server/cql_proxy.go
	CGOENABLED=0 GOOS=linux GOARCH=amd64 go build -o server/cql_proxy.bin server/cql_proxy.go

server/server.img: server/server.sh server/cql_proxy.bin server/server-base.sh server/gunicorn_conf.py twissandra/twissandra twissandra/__init__.py twissandra/manage.py twissandra/twissandra
	@docker run --rm -v $(PWD)/server/server.sh:/app.sh -v $(PWD)/server/server-base.sh:/base.sh -v $(PWD)/server/cql_proxy.bin:/files/cql_proxy.bin -v $(PWD)/server/gunicorn_conf.py:/files/twissandra/gunicorn_conf.py -v $(PWD)/twissandra/__init__.py:/files/twissandra/__init__.py -v $(PWD)/twissandra/manage.py:/files/twissandra/manage.py -v $(PWD)/twissandra/twissandra:/files/twissandra/twissandra -v $(PWD):/opt/code --privileged rootfsbuilder $@

combined/combined.img: combined/combined.sh combined/combined-base.sh
	@docker run --rm -v $(PWD)/combined/combined.sh:/app.sh -v $(PWD)/combined/combined-base.sh:/base.sh -v $(PWD)/server/gunicorn_conf.py:/files/twissandra/gunicorn_conf.py -v $(PWD)/twissandra/__init__.py:/files/twissandra/__init__.py -v $(PWD)/twissandra/manage.py:/files/twissandra/manage.py -v $(PWD)/twissandra/twissandra:/files/twissandra/twissandra -v $(PWD):/opt/code --privileged rootfsbuilder $@