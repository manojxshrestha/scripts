#!/usr/bin/env bash

# Check if a domain is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

for one in `cat commonwords.txt`
do
    echo "$one.$1"
    for num in {1..5}
    do
        echo "$one$num.$1"
    done
    for two in `cat commonwords.txt`
    do
        echo "$two.$one.$1"
        echo "$two$one.$1"
        echo "$two-$one.$1"
        for num in {1..5}
        do
            echo "$two.$one$num.$1"
            echo "$two-$one$num.$1"
        done
    done
done
