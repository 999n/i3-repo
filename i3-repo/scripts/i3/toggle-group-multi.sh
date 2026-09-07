#!/bin/bash
# toggle-group-multi.sh — show/hide all windows in a group, snapped to workspace free zone

group=$1
state_dir="/tmp/i3-groups"
mkdir -p "$state_dir"

state_file="$state_dir/g${group}.state"
state=$(cat "$state_file" 2>/dev/null || echo "hidden")
tree=$(i3-msg -t get_tree)

# Derive zone from actual workspace geometry
ws=$(i3-msg -t get_workspaces | jq '.[] | select(.focused) | .rect')
WX=$(echo "$ws" | jq '.x')
WW=$(echo "$ws" | jq '.width')
SW=$(i3-msg -t get_outputs | jq '[.[] | select(.active)] | .[0].rect.width')
SH=$(i3-msg -t get_outputs | jq '[.[] | select(.active)] | .[0].rect.height')
ZONE_X=$(( WX + WW ))
ZONE_W=$(( SW - ZONE_X ))
ZONE_H=$(( SH - 52 ))  # top+bottom bar

for i in {1..8}; do
  mark="g${group}_${i}"
  has=$(echo "$tree" | jq -r ".. | objects | select(.marks? and (.marks | index(\"$mark\"))) | .id" 2>/dev/null | head -1)
  [ -z "$has" ] && continue

  if [ "$state" = "visible" ]; then
    i3-msg "[con_mark=\"$mark\"] move scratchpad"
  else
    i3-msg "[con_mark=\"$mark\"] scratchpad show"
    sleep 0.1
    i3-msg "[con_mark=\"$mark\"] resize set $ZONE_W $ZONE_H, move position $ZONE_X 0"
  fi
done

[ "$state" = "visible" ] && echo "hidden" > "$state_file" || echo "visible" > "$state_file"
