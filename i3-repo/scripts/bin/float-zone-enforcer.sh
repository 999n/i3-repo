#!/bin/bash
# float-zone-enforcer.sh — snap floats back to right zone if they drift left

i3-msg -t subscribe '["window"]' | jq -r --unbuffered '
  select(.change == "floating" or .change == "move") |
  select(.container.floating == "user_on" or .container.floating == "auto_on") |
  select(.container.window_type != "dialog" and .container.window_role != "dialog" and .container.window_role != "GtkFileChooserDialog" and .container.window_role != "pop-up" and .container.window_role != "task_dialog") |
  "\(.container.id) \(.container.rect.x) \(.container.rect.y)"
' | while read -r id x y; do
  [ -f /tmp/float-layout-running ] && continue
  [ -f /tmp/float-active-layout ] || continue
  sleep 0.1

  # Get the workspace this window actually lives on, not just the focused one
  win_ws=$(i3-msg -t get_tree | jq -r --argjson id "$id" '
    .. | objects | select(.id == $id) |
    path(.. | objects | select(.id == $id)) as $p |
    . as $root |
    ($root | .nodes[]? | select(.. | objects | .id? == $id) | .name) // empty
  ' 2>/dev/null | head -1)

  ws=$(i3-msg -t get_workspaces | jq --arg name "$win_ws" '.[] | select(.name == $name) | .rect')
  [ -z "$ws" ] && ws=$(i3-msg -t get_workspaces | jq '.[] | select(.focused) | .rect')

  ws_x=$(echo "$ws" | jq '.x')
  ws_w=$(echo "$ws" | jq '.width')
  FREE_X=$(( ws_x + ws_w ))

  if [ "$x" -lt "$FREE_X" ]; then
    i3-msg "[con_id=$id] move position $FREE_X $y"
  fi
done
