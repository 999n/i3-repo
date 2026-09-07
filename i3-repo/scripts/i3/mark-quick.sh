#!/bin/bash
# Add window to quick access with unique mark

for i in {1..20}; do
    exists=$(i3-msg -t get_tree | jq ".. | objects | select(.marks? and (.marks | index(\"quick$i\")))" | wc -l)
    if [ "$exists" -eq 0 ]; then
        i3-msg "mark --add \"quick$i\"" > /dev/null
        exit 0
    fi
done
