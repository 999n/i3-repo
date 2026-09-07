#!/bin/bash

while true
do
    pkill -9 keynav 2>/dev/null

    keynav &

    sleep 60
done
