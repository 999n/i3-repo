#!/bin/bash
# add-to-group.sh — add focused window to next free slot in group
#
# If the focused window already occupies a slot in this group, its old
# slot mark is released first, so re-sending the same window MOVES it to
# the next free slot instead of stacking duplicate marks on top of it.

group=$1
state_dir="/tmp/i3-groups"
mkdir -p "$state_dir"

tree=$(i3-msg -t get_tree)

# Release the focused window's own slots in this group (if any)
own_marks=$(echo "$tree" | jq -r '
  .. | objects
  | select(.focused? == true)
  | .marks[]?
  | select(test("^g'"$group"'_[0-9]+$"))' 2>/dev/null)

while IFS= read -r m; do
  [[ -n "$m" ]] && i3-msg "mark --toggle \"$m\"" > /dev/null 2>&1
done <<< "$own_marks"

# Fresh tree: all marks currently in use
used_marks=$(i3-msg -t get_tree | jq -r '.. | objects | select(.marks?) | .marks[]' 2>/dev/null)

for i in {1..8}; do
  mark="g${group}_${i}"
  if ! echo "$used_marks" | grep -qx "$mark"; then
    WIN=$(xdotool getactivewindow)
    GEOM=$(xdotool getwindowgeometry "$WIN" 2>/dev/null)
    W=$(echo "$GEOM" | grep -oP 'Geometry: \K\d+(?=x)')
    H=$(echo "$GEOM" | grep -oP 'x\K\d+')
    POS=$(echo "$GEOM" | awk '/Position/{print $2}')
    echo "$W $H ${POS//,/ }" > "$state_dir/g${group}_${i}.geom"
    i3-msg "floating enable; mark --add \"$mark\"; move scratchpad"
    echo "hidden" > "$state_dir/g${group}.state"
    exit 0
  fi
done

notify-send "i3 groups" "Group $group is full (max 8 windows)"
