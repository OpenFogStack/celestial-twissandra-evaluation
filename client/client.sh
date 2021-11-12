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

# configure and run twissandra proxy
./http_proxy --hosts=tw1.gst.celestial,tw2.gst.celestial,tw3.gst.celestial
export TWISSANDRA_HOST="localhost"
export TWISSANDRA_PORT="80"

locust --csv-full-history --csv=/stats--headless --users 1 -H http://"$TWISSANDRA_HOST":"$PORT"