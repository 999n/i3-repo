#!/bin/bash
# Cycle through windows in active group

GROUPS_FILE="/tmp/i3_groups.json"
ACTIVE_FILE="/tmp/i3_active_group"

[[ ! -s "$GROUPS_FILE" ]] && { dunstify -u critical "No groups saved"; exit 1; }
[[ ! -s "$ACTIVE_FILE" ]] && { dunstify -u critical "No active group"; exit 1; }

ACTIVE_GROUP=$(cat "$ACTIVE_FILE")
GROUPS=$(cat "$GROUPS_FILE")

# Get window IDs from active group
WINDOW_IDS=$(echo "$GROUPS" | jq -r ".\"$ACTIVE_GROUP\" | .[].id" 2>/dev/null)
[[ -z "$WINDOW_IDS" ]] && { dunstify -u critical "Group '$ACTIVE_GROUP' not found"; exit 1; }

# Get currently focused window
FOCUSED=$(i3-msg -t get_tree | jq -r 'recurse | objects | select(.focused == true) | .id' | head -1)

# Find next window
FOUND=0
NEXT_WID=""
FIRST_WID=""

while read -r wid; do
    [[ -z "$FIRST_WID" ]] && FIRST_WID="$wid"
    [[ $FOUND -eq 1 ]] && { NEXT_WID="$wid"; break; }
    [[ "$wid" == "$FOCUSED" ]] && FOUND=1
done <<< "$WINDOW_IDS"

# Wrap around
[[ -z "$NEXT_WID" ]] && NEXT_WID="$FIRST_WID"

# Focus and notify
i3-msg "[id=\"$NEXT_WID\"] focus" > /dev/null
TITLE=$(i3-msg -t get_tree | jq -r "recurse | objects | select(.id == $NEXT_WID) | .name" | head -1)
dunstify -u low "→ $TITLE" -t 800
