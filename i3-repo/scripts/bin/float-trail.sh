#!/bin/bash
# float-trail.sh — focus-trail mode (no compositor needed)
# Focused float stays visible. All others parked off-screen right edge.
# Focus switches → previous parks, newly focused restores.

STATE=/tmp/float-trail-active
DAEMON_PID=/tmp/float-trail-pid
POSITIONS=/tmp/float-trail-positions  # "con_id x y w h" per line

SW=$(xdpyinfo | awk '/dimensions:/{split($2,a,"x"); print a[1]}')
PARK_X=$(( SW + 10 ))  # just off-screen

park() {
  local id=$1
  i3-msg "[con_id=$id] move position $PARK_X 100" >/dev/null
}

restore() {
  local id=$1
  local entry
  entry=$(grep "^$id " "$POSITIONS" 2>/dev/null)
  [ -z "$entry" ] && return
  read -r _ x y w h <<< "$entry"
  i3-msg "[con_id=$id] resize set $w $h, move position $x $y" >/dev/null
}

save_pos() {
  local id=$1
  local info
  info=$(i3-msg -t get_tree | jq -r --argjson id "$id" '
    .. | objects | select(.id == $id) | select(.window != null) |
    "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"' | head -1)
  [ -z "$info" ] && return
  sed -i "/^$id /d" "$POSITIONS" 2>/dev/null
  echo "$id $info" >> "$POSITIONS"
}

get_floats() {
  i3-msg -t get_tree | jq -r '
    .. | objects | select(.window != null) |
    select(.floating? == "user_on" or .floating? == "auto_on") |
    .id'
}

# --- TOGGLE OFF ---
if [ -f "$STATE" ]; then
  [ -f "$DAEMON_PID" ] && kill "$(cat "$DAEMON_PID")" 2>/dev/null
  # Restore all parked windows
  while read -r id x y w h; do
    i3-msg "[con_id=$id] resize set $w $h, move position $x $y" >/dev/null
  done < "$POSITIONS"
  rm -f "$STATE" "$DAEMON_PID" "$POSITIONS"
  dunstify -u low -t 1200 "focus-trail: off"
  exit 0
fi

# --- TOGGLE ON ---
touch "$STATE"
> "$POSITIONS"
dunstify -u low -t 1200 "focus-trail: on"

TREE=$(i3-msg -t get_tree)
focused_id=$(echo "$TREE" | jq -r '.. | objects | select(.focused==true) | select(.window!=null) | .id' | head -1)

# Save all float positions, park all except focused
while read -r id; do
  save_pos "$id"
  [ "$id" != "$focused_id" ] && park "$id"
done < <(get_floats)

# Daemon: on focus change, park old, restore new
(
  prev_id="$focused_id"
  i3-msg -t subscribe '["window"]' | jq -r --unbuffered '
    select(.change == "focus") |
    select(.container.floating == "user_on" or .container.floating == "auto_on") |
    .container.id
  ' | while read -r new_id; do
    [ ! -f "$STATE" ] && break
    [ "$new_id" = "$prev_id" ] && continue
    # Save current position of newly focused (in case it moved while parked)
    save_pos "$new_id"
    # Park the previously focused
    [ -n "$prev_id" ] && park "$prev_id"
    # Restore the newly focused
    restore "$new_id"
    prev_id="$new_id"
  done
) &

echo $! > "$DAEMON_PID"
