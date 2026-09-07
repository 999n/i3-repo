#!/bin/bash
# stale-window-marker.sh — mark windows unfocused for >STALE_MINS with loud border
# On focus, the mark is removed and border resets.

STALE_MINS=15
TIMESTAMP_FILE="/tmp/i3-focus-timestamps"
STALE_MARK="stale_loud"

mark_stale() {
  local id=$1
  i3-msg "[con_id=$id] mark --add $STALE_MARK" &>/dev/null
  # Use urgency to trigger client.urgent color (the only per-window color hook i3 has)
  xdotool getwindowfocus &>/dev/null  # no-op, urgency set via xprop
  xprop -id "$(i3-msg -t get_tree | jq ".. | objects | select(.id==$id) | .window // empty" 2>/dev/null | head -1)" \
    -f WM_HINTS 32i -set WM_HINTS "67,0,0,0,0,0,0,0,0" &>/dev/null || true
}

unmark_stale() {
  local id=$1
  i3-msg "[con_id=$id] unmark $STALE_MARK" &>/dev/null
}

# Watch for focus events to immediately unmark when a window is touched
(i3-msg -t subscribe '["window"]' | jq -r --unbuffered '
  select(.change == "focus") | .container.id
' | while read -r id; do
  unmark_stale "$id"
done) &

# Every 60s, check all windows against their last-focus timestamp
while true; do
  sleep 60
  [ ! -f "$TIMESTAMP_FILE" ] && continue

  now=$(date +%s)
  stale_threshold=$(( STALE_MINS * 60 ))

  # Get all alive window IDs
  alive=$(i3-msg -t get_tree | jq '[.. | objects | select(.window != null) | .id]')

  while read -r id last_seen; do
    # Skip if window no longer exists
    echo "$alive" | jq -e "index($id)" &>/dev/null || continue
    age=$(( now - last_seen ))
    if [ "$age" -ge "$stale_threshold" ]; then
      mark_stale "$id"
    fi
  done < "$TIMESTAMP_FILE"
done
