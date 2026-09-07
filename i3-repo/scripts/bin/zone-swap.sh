#!/bin/bash
# zone-swap.sh — swap tiled/float zones by flipping the right gap
# Normal: gaps right 600 (tiled left ~1320px, float right ~600px)
# Swapped: gaps right 1320 (tiled left ~600px, float right ~1320px)

STATE=/tmp/zone-swapped
NORMAL_GAP=600
SWAPPED_GAP=1320

move_floats() {
  local x=$1
  i3-msg -t get_tree | jq -r '.. | select(.floating? and (.floating | test("user_on|auto_on"))) | .id' | \
  while read -r id; do
    i3-msg "[con_id=$id] move position $x center"
  done
}

if [ -f "$STATE" ]; then
  i3-msg "gaps right current set $NORMAL_GAP"
  move_floats 1320
  rm -f "$STATE"
  dunstify -u low -t 1200 "zone: normal (float right)"
else
  i3-msg "gaps right current set $SWAPPED_GAP"
  move_floats 0
  touch "$STATE"
  dunstify -u low -t 1200 "zone: swapped (float left)"
fi

# Re-run active layout if one is set
[ -f /tmp/float-active-layout ] && bash "$(cat /tmp/float-active-layout)"
