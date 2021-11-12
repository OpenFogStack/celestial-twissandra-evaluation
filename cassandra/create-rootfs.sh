#!/bin/sh

#
# This file is part of Celestial's Videoconferencing Evaluation
# (https://github.com/OpenFogStack/celestial-videoconferencing-evaluation).
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

docker build -t cassandra-rootfs .
mkdir ./tmp

docker run --rm -i -v "$(pwd)/tmp:/my-rootfs" cassandra-rootfs -c 'for d in bin etc lib root sbin usr; do tar c "/$d" | tar x -C /my-rootfs; done ; for dir in dev proc run sys var; do mkdir /my-rootfs/${dir}; done ; exit'

cp interfaces ./tmp/etc/network/interfaces

mkdir -p ./tmp/overlay/root \
    ./tmp/overlay/work \
    ./tmp/mnt \
    ./tmp/rom

xattr -dsr com.docker.grpcfuse.ownership ./tmp

mksquashfs ./tmp rootfs.img -noappend

rm -rdf ./tmp