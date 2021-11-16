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
CASS_DRIVER_NO_CYTHON=1 python3 -m pip install --no-cache-dir cassandra-driver==3.6.0
python3 -m pip install --no-cache-dir Django==1.11.29 python-lorem==1.1.2 pytz==2021.3 simplejson==3.17.5 tqdm==4.62.3 beautifulsoup4==4.10.0