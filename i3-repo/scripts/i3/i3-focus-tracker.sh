#!/bin/bash
# i3-focus-tracker.sh — track focus history + last-focus timestamps

HISTORY_FILE="/tmp/i3-focus-history"
TIMESTAMP_FILE="/tmp/i3-focus-timestamps"
touch "$HISTORY_FILE" "$TIMESTAMP_FILE"

i3-msg -t subscribe '["window"]' | jq -r --unbuffered '
  select(.change == "focus") | .container.id
' | while read -r con_id; do
  [ -z "$con_id" ] && continue
  { echo "$con_id"; grep -v "^$con_id$" "$HISTORY_FILE"; } | head -10 > "${HISTORY_FILE}.tmp"
  mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
  # update timestamp: "con_id epoch"
  grep -v "^$con_id " "$TIMESTAMP_FILE" > "${TIMESTAMP_FILE}.tmp"
  echo "$con_id $(date +%s)" >> "${TIMESTAMP_FILE}.tmp"
  mv "${TIMESTAMP_FILE}.tmp" "$TIMESTAMP_FILE"
done
