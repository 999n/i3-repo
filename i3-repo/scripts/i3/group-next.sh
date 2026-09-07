#!/bin/bash
# Focus next window in active group

GROUPS_FILE="/tmp/i3_groups.json"
ACTIVE_FILE="/tmp/i3_active_group"

# Clean up dead windows (windows that were closed)
ACTIVE_MARKS=$(i3-msg -t get_marks 2>/dev/null || echo "[]")
jq --argjson am "$ACTIVE_MARKS" 'map_values(map(select(.mark as $m | $am | index($m))))' "$GROUPS_FILE" > "${GROUPS_FILE}.tmp" && mv "${GROUPS_FILE}.tmp" "$GROUPS_FILE"


[[ ! -s "$GROUPS_FILE" ]] && { dunstify -u critical "No groups saved"; exit 1; }
[[ ! -s "$ACTIVE_FILE" ]] && { dunstify -u critical "No active group"; exit 1; }

GROUP=$(cat "$ACTIVE_FILE")
MARKS=$(jq -r --arg g "$GROUP" '.[$g] // empty | .[].mark' "$GROUPS_FILE")
[[ -z "$MARKS" ]] && { dunstify -u critical "Group '$GROUP' not found"; exit 1; }

FOCUSED=$(i3-msg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(type == "object" and .focused == true) | .marks[0] // empty' | head -1)

MARKS_ARRAY=()
while read -r mark; do
    MARKS_ARRAY+=("$mark")
done <<< "$MARKS"

TOTAL=${#MARKS_ARRAY[@]}
[[ $TOTAL -eq 0 ]] && { dunstify -u critical "Group '$GROUP' is empty"; exit 1; }

# Find index of currently focused window in group
FOCUSED_IDX=-1
for i in "${!MARKS_ARRAY[@]}"; do
    if [[ "${MARKS_ARRAY[$i]}" == "$FOCUSED" ]]; then
        FOCUSED_IDX=$i
        break
    fi
done

# Next index (wrap around), if focused not in group start from 0
if [[ $FOCUSED_IDX -eq -1 ]]; then
    NEXT_IDX=0
else
    NEXT_IDX=$(( (FOCUSED_IDX + 1) % TOTAL ))
fi

NEXT="${MARKS_ARRAY[$NEXT_IDX]}"

# Get workspace of the target window and switch to it first, then focus
WS=$(i3-msg -t get_tree | jq -r --arg m "$NEXT" '
  recurse(.nodes[]?) | select(.type == "workspace") | . as $ws |
  recurse(.nodes[]?, .floating_nodes[]?) |
  select(type == "object") | select(.marks[]? == $m) |
  $ws.name' | head -1)

[[ -n "$WS" ]] && i3-msg "workspace $WS" > /dev/null 2>&1
i3-msg "[con_mark=\"$NEXT\"] focus" > /dev/null 2>&1
TITLE=$(i3-msg -t get_tree | jq -r --arg m "$NEXT" 'recurse(.nodes[]?, .floating_nodes[]?) | select(type == "object") | select(.marks[]? == $m) | .name' | head -1)
dunstify -u low -r 9910 "→ $TITLE  [$GROUP]" -t 800
