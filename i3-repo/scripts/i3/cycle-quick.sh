#!/bin/bash
direction=${1:-forward}

windows=($(i3-msg -t get_tree | jq -r '.. | objects | select(.marks? and (.marks[] | test("^quick[0-9]+$"))) | .id'))

[ ${#windows[@]} -eq 0 ] && exit 0
[ ${#windows[@]} -eq 1 ] && exit 0

focused=$(i3-msg -t get_tree | jq -r '.. | objects | select(.focused==true) | .id')

for i in "${!windows[@]}"; do
    if [ "${windows[$i]}" = "$focused" ]; then
        if [ "$direction" = "reverse" ]; then
            next_idx=$(( (i - 1 + ${#windows[@]}) % ${#windows[@]} ))
        else
            next_idx=$(( (i + 1) % ${#windows[@]} ))
        fi
        i3-msg "[con_id=\"${windows[$next_idx]}\"] focus" > /dev/null
        exit 0
    fi
done

i3-msg "[con_id=\"${windows[0]}\"] focus" > /dev/null
