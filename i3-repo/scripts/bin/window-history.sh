#!/bin/bash
# window-history.sh — jump to recently focused windows in order

HISTORY_FILE="/tmp/i3-focus-history"
[ -f "$HISTORY_FILE" ] || exit 0

TREE=$(i3-msg -t get_tree)

list=""
while read -r con_id; do
  entry=$(echo "$TREE" | jq -r --argjson id "$con_id" '
    .. | objects | select(.id == $id) |
    "\(if .floating == "user_on" then "[F] " else "" end)\(.name // "(no title)")\t\(.window_properties.class // "")"
  ' 2>/dev/null | head -1)
  [ -z "$entry" ] && continue
  title=$(echo "$entry" | cut -f1)
  class=$(echo "$entry" | cut -f2)
  list+="$(printf '%-50s (%s)' "$title" "$class")|$con_id"$'\n'
done < "$HISTORY_FILE"

[ -z "$list" ] && exit 0

theme=$(ls ~/rofi-themes-collection/themes/*.rasi 2>/dev/null | shuf -n1)
theme_arg=(); [ -n "$theme" ] && theme_arg=(-theme "$theme")

selected=$(echo "$list" | grep -v '^$' | rofi -dmenu -p "history" -i -format d "${theme_arg[@]}" 2>/dev/null)
[ -z "$selected" ] && exit 0

con_id=$(echo "$list" | grep -v '^$' | sed -n "${selected}p" | awk -F'|' '{print $NF}')
[ -z "$con_id" ] && exit 0

i3-msg "[con_id=$con_id] focus"
