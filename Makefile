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

all: client.img server.img cassandra.img

client/http_proxy: client/http_proxy.go
	CGOENABLED=0 GGOOS=linux GOARCH=amd64 go build -o client/http_proxy client/http_proxy.go

client/client.img: client/client.sh client/client-base.sh client/http_proxy twissandra/benchmark/locustfile.py
	@docker run --rm -v $(PWD)/client/client.sh:/app.sh -v $(PWD)/client/client-base.sh:/base.sh -v $(PWD)/client/http_proxy:/files/http_proxy -v $(PWD)/twissandra/benchmark/locustfile.py:/files/locustfile.py -v $(PWD)/client:/opt/code --privileged rootfsbuilder $@

cassandra/cassandra.img: cassandra/Dockerfile cassandra/create-rootfs.sh cassandra/interfaces
	@cd cassandra && sh create-roots.sh && cd ..

server/cql_proxy: server/cql_proxy.go
	CGOENABLED=0 GOOS=linux GOARCH=amd64 go build -o server/cql_proxy server/cql_proxy.go

server/server.img: server/server.sh server/server-base.sh server/gunicorn_conf.py twissandra/twissandra twissandra/__init__.py twissandra/manage.py twissandra/twissandra
	@docker run --rm -v $(PWD)/server/server.sh:/app.sh -v $(PWD)/server/server-base.sh:/base.sh -v $(PWD)/server/cql_proxy:/files/cql_proxy -v $(PWD)/server/gunicorn_conf.py:/gunicorn_conf.py -v $(PWD)/twissandra/__init__.py:/files/__init__.py -v $(PWD)/twissandra/manage.py:/files/manage.py -v $(PWD)/twissandra/twissandra:/files/twissandra -v $(PWD)/server:/opt/code --privileged rootfsbuilder $@