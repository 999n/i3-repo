#!/bin/bash
# window-jump.sh — fuzzy jump to any window across all workspaces
# Shows: [workspace] title (class)

TREE=$(i3-msg -t get_tree)

# Build list: "con_id\t[ws] title (class)"
declare -A entries
while IFS=$'\t' read -r id ws title class; do
  [ -z "$title" ] && title="(no title)"
  entries["$id"]="$(printf '[%-6s]  %s  (%s)' "$ws" "$title" "$class")"
done < <(echo "$TREE" | jq -r '
  .. | objects | select(.window != null) |
  select(.type? == "con") |
  "\(.id)\t\(.workspace? // "")\t\(.name // "")\t\(.window_properties.class // "")"
' 2>/dev/null)

# Fallback: get workspace per window via tree traversal
list=""
while IFS=$'\t' read -r id ws_name title class; do
  [ -z "$title" ] && title="(no title)"
  line="$(printf '[%-8s]  %-45s  (%s)' "$ws_name" "$title" "$class")|$id"
  list+="$line"$'\n'
done < <(echo "$TREE" | jq -r '
  .. | objects | select(.type? == "workspace") |
  . as $ws |
  (.. | objects | select(.window != null) | select(.type? == "con")) |
  "\(.id)\t\($ws.name)\t\(if .floating == "user_on" then "[F] " else "" end)\(.name // "")\t\(.window_properties.class // "")"
' 2>/dev/null)

[ -z "$list" ] && exit 0

theme=$(ls ~/rofi-themes-collection/themes/*.rasi 2>/dev/null | shuf -n1)
theme_arg=()
[ -n "$theme" ] && theme_arg=(-theme "$theme")

selected=$(echo "$list" | grep -v '^$' | \
  rofi -dmenu -p "jump to" -i -format d "${theme_arg[@]}" 2>/dev/null)

[ -z "$selected" ] && exit 0

# Get the con_id from selected line
con_id=$(echo "$list" | grep -v '^$' | sed -n "${selected}p" | awk -F'|' '{print $NF}')
[ -z "$con_id" ] && exit 0

i3-msg "[con_id=$con_id] focus"
