#!/bin/bash

# usage: run-cluster.sh <name> <number>
# check that we got the parameter we needed or exit the script with a usage message
[ $# -ne 2 ] && { echo "Usage: $0 name number"; exit 1; }

name=$1
number=$2

results_dir="./results/results-$name-$number"

mkdir ./mnt_tmp

mkdir -p "$results_dir"

for d in /celestial/ce*.ext4 ; do
    bname=$(basename "$d")
    echo "mounting $d"
    sudo mount -t ext4 -o loop "$d" ./mnt_tmp
    echo "mounting $d done"
    echo "copying results"
    cp -r ./mnt_tmp/root/stats--headless_exceptions.csv "$results_dir/$bname-exceptions.csv"
    cp -r ./mnt_tmp/root/stats--headless_failures.csv "$results_dir/$bname-failures.csv"
    cp -r ./mnt_tmp/root/stats--headless_stats.csv "$results_dir/$bname-stats.csv"
    cp -r ./mnt_tmp/root/stats--headless_stats_history.csv "$results_dir/$bname-history.csv"

    echo "copying results done"
    echo "unmounting $d"
    sudo umount ./mnt_tmp
    echo "unmounting $d done"
done

rm -rfd ./mnt_tmp