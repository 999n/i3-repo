#!/bin/bash
# toggle-group.sh — show/hide all windows of a group.
#
# i3 quirks this works around (verified on 4.24):
#   * `move scratchpad` silently ignores criteria — it only acts on the
#     FOCUSED window, even though it replies success:true.
#   * `move container to workspace` behaves the same way.
#   * `scratchpad show` respects criteria, but is a no-op (with an
#     error) for windows that are not in the scratchpad.
#
# Because single attempts can silently fail, every action is verified
# against the live tree and retried a few times until it sticks.
#
# show: pull every member out of the scratchpad onto your current
#       workspace as a floating overlay, restoring its saved geometry.
# hide: stash every member back into the scratchpad.
#
# Which way to toggle comes from the state file written by
# add-to-group.sh.

group=$1
state_dir="/tmp/i3-groups"
state_file="$state_dir/g${group}.state"
mkdir -p "$state_dir"

tree=$(i3-msg -t get_tree)

# Unique members: "con_id|slot|current_workspace" (first group mark wins)
windows=$(echo "$tree" | jq -r --arg g "g${group}_" '
  [ .. | objects | select(.type? == "output") as $o
    | (.. | objects | select(.type? == "workspace") as $w
       | (.. | objects
          | select((.marks // []) | any(test("^" + $g + "[0-9]+$")))
          | . as $c
          | ($c.marks
             | map(select(test("^" + $g + "[0-9]+$")))
             | .[0]
             | capture("^(?<g>g[0-9]+)_(?<n>[0-9]+)$").n) as $slot
          | {id: $c.id, slot: $slot, ws: $w.name}))]
| unique_by(.id) | .[] | "\(.id)|\(.slot)|\(.ws)"' 2>/dev/null)

[[ -z "$windows" ]] && exit 0

orig_focus=$(echo "$tree" | jq -r '.. | objects | select(.focused? == true) | .id' 2>/dev/null | head -1)
member_ids=$(echo "$windows" | cut -d'|' -f1)
cur_ws=$(i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused? == true) | .name' 2>/dev/null | head -1)

# ids of members that are NOT inside the scratchpad
still_outside() {
  i3-msg -t get_tree | jq -r --arg g "g${group}_" '
    [ .. | objects | select(.type? == "output") as $o
      | (.. | objects | select(.type? == "workspace") as $w
         | (.. | objects
            | select($w.name != "__i3_scratch")
            | select((.marks // []) | any(test("^" + $g + "[0-9]+$")))
            | .id))] | unique | .[]' 2>/dev/null
}

# ids of members that are NOT floating overlays on the current workspace
still_not_on() {
  local target=$1
  i3-msg -t get_tree | jq -r --arg g "g${group}_" --arg ws "$target" '
    [ .. | objects | select(.type? == "output") as $o
      | (.. | objects | select(.type? == "workspace") as $w
         | (.. | objects
            | select($w.name != $ws)
            | select((.marks // []) | any(test("^" + $g + "[0-9]+$")))
            | .id))] | unique | .[]' 2>/dev/null
}

state=$(cat "$state_file" 2>/dev/null)

if [ "$state" = "visible" ]; then
    # ── HIDE: stash every member into the scratchpad (with retries) ──
    for attempt in 1 2 3 4; do
      pending=$(still_outside)
      [[ -z "$pending" ]] && break
      while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        i3-msg "[con_id=$id] focus; move scratchpad" > /dev/null 2>&1
      done <<< "$pending"
      sleep 0.3
    done
    echo "hidden" > "$state_file"
else
    # ── SHOW: pull every member out onto your current workspace ──
    while IFS='|' read -r id slot ws; do
      [[ -z "$id" ]] && continue
      # members that drifted outside the scratchpad must be stashed
      # first — scratchpad show only affects scratchpad windows
      if [[ "$ws" != "__i3_scratch" ]]; then
        i3-msg "[con_id=$id] focus; move scratchpad" > /dev/null 2>&1
        sleep 0.2
      fi
      cmd="workspace \"$cur_ws\"; [con_id=$id] scratchpad show"
      geom_file="$state_dir/g${group}_${slot}.geom"
      if [[ -f "$geom_file" ]]; then
        read -r W H X Y < "$geom_file"
        [[ -n "$W" && -n "$H" ]] && cmd="$cmd; [con_id=$id] resize set $W $H; [con_id=$id] move position $X $Y"
      fi
      i3-msg "$cmd" > /dev/null 2>&1
      sleep 0.2
    done <<< "$windows"
    # consolidation retries: anything that did not land on your
    # workspace gets focus-chained there
    for attempt in 1 2 3; do
      pending=$(still_not_on "$cur_ws")
      [[ -z "$pending" ]] && break
      while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        i3-msg "[con_id=$id] focus; move container to workspace \"$cur_ws\"" > /dev/null 2>&1
      done <<< "$pending"
      sleep 0.3
    done
    echo "visible" > "$state_file"
fi

# Give focus back to what you were doing
if [[ -n "$orig_focus" ]] && ! echo "$member_ids" | grep -qx "$orig_focus"; then
    i3-msg "[con_id=$orig_focus] focus" > /dev/null 2>&1
fi
