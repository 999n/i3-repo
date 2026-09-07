#!/bin/bash
# float-record-size.sh — record focused floating window size after manual resize keybinding

MANUAL=/tmp/float-manual-sizes
touch "$MANUAL"

read -r id w h < <(i3-msg -t get_tree | jq -r '
  .. | objects |
  select(.focused==true) |
  select(.window!=null) |
  select(.floating?=="user_on" or .floating?=="auto_on") |
  "\(.id) \(.rect.width) \(.rect.height)"
' | head -1)

[ -z "$id" ] && exit 0
sed -i "/^$id /d" "$MANUAL"
echo "$id $w $h" >> "$MANUAL"
