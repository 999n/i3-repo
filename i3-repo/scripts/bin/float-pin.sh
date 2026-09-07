#!/bin/bash
# float-pin.sh — pin/unpin focused floating window from layout management
# Pinned windows are ignored by all layout scripts and the zone enforcer.

PINNED=/tmp/float-pinned-ids
touch "$PINNED"

id=$(i3-msg -t get_tree | jq -r '
  .. | objects | select(.focused==true) | select(.window!=null) | .id' | head -1)
[ -z "$id" ] && exit 0

title=$(i3-msg -t get_tree | jq -r --argjson id "$id" '
  .. | objects | select(.id==$id) | .name' | head -1 | cut -c1-40)

if grep -qx "$id" "$PINNED" 2>/dev/null; then
  sed -i "/^${id}$/d" "$PINNED"
  dunstify -u low -t 1500 "unpinned: $title"
else
  echo "$id" >> "$PINNED"
  dunstify -u low -t 1500 "pinned: $title (layout won't touch it)"
fi
