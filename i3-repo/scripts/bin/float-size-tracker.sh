#!/bin/bash
# float-size-tracker.sh — record manual resizes, skip layout-driven ones

MANUAL=/tmp/float-manual-sizes
touch "$MANUAL"

i3-msg -t subscribe '["window"]' | jq -r --unbuffered '
  select(.change == "resize" or .change == "floating") |
  select(.container.floating == "user_on" or .container.floating == "auto_on") |
  "\(.container.id) \(.container.rect.width) \(.container.rect.height)"
' | while read -r id w h; do
  [ -f /tmp/float-layout-running ] && continue
  sed -i "/^$id /d" "$MANUAL"
  echo "$id $w $h" >> "$MANUAL"
done
