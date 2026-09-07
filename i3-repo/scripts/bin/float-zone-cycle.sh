#!/bin/bash
# Cycle focus through floating windows in the right zone (x >= 960)
TREE=$(i3-msg -t get_tree)

FOCUSED=$(echo "$TREE" | jq -r '.. | objects | select(.focused == true) | .id')

mapfile -t IDS < <(echo "$TREE" | jq -r '
  .. | objects
  | select(.floating? == "user_on" or .floating? == "auto_on")
  | select(.rect.x >= 960)
  | .id
')

[[ ${#IDS[@]} -eq 0 ]] && exit 0

NEXT=0
for i in "${!IDS[@]}"; do
    [[ "${IDS[$i]}" == "$FOCUSED" ]] && NEXT=$(( (i + 1) % ${#IDS[@]} )) && break
done

i3-msg "[con_id=${IDS[$NEXT]}] focus"
