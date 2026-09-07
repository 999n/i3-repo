#!/bin/bash
# focus-lock.sh — lock focus to current window
# Disables focus_follows_mouse and intercepts focus-change events.
# Press again to unlock.

STATE=/tmp/focus-lock-id
DAEMON_PID=/tmp/focus-lock-pid

# --- UNLOCK ---
if [ -f "$STATE" ]; then
  [ -f "$DAEMON_PID" ] && kill "$(cat "$DAEMON_PID")" 2>/dev/null
  rm -f "$STATE" "$DAEMON_PID"
  i3-msg "focus_follows_mouse yes" >/dev/null
  dunstify -u low -t 1200 "focus lock: off"
  exit 0
fi

# --- LOCK ---
locked_id=$(i3-msg -t get_tree | jq -r '
  .. | objects | select(.focused==true) | select(.window!=null) | .id' | head -1)
[ -z "$locked_id" ] && exit 0

echo "$locked_id" > "$STATE"
i3-msg "focus_follows_mouse no" >/dev/null
dunstify -u low -t 1200 "focus lock: on — $(i3-msg -t get_tree | jq -r --argjson id "$locked_id" '.. | objects | select(.id==$id) | .name' | head -1 | cut -c1-40)"

# Daemon: if focus ever leaves the locked window, yank it back
(
  i3-msg -t subscribe '["window"]' | jq -r --unbuffered '
    select(.change == "focus") | .container.id
  ' | while read -r new_id; do
    [ ! -f "$STATE" ] && break
    locked=$(cat "$STATE")
    [ "$new_id" = "$locked" ] && continue
    i3-msg "[con_id=$locked] focus" >/dev/null
  done
) &

echo $! > "$DAEMON_PID"
