#!/bin/bash
# float-hide-all.sh — send all visible floats to scratchpad, restore on second press

STATE=/tmp/float-hide-all

if [ -f "$STATE" ]; then
  # Restore — bring each saved id back from scratchpad
  while read -r id; do
    i3-msg "[con_id=$id] scratchpad show" >/dev/null
  done < "$STATE"
  rm -f "$STATE"
  dunstify -u low -t 1000 "floats: restored"
  exit 0
fi

# Hide — scratchpad all visible floats
ids=$(i3-msg -t get_tree | jq -r '
  .. | objects |
  select(.floating? == "user_on" or .floating? == "auto_on") |
  select(.window != null) |
  .id')

[ -z "$ids" ] && exit 0

echo "$ids" > "$STATE"
while read -r id; do
  i3-msg "[con_id=$id] move scratchpad" >/dev/null
done <<< "$ids"
dunstify -u low -t 1000 "floats: hidden ($(echo "$ids" | wc -l) windows)"
