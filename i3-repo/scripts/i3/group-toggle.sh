#!/bin/bash
# Quick toggle between last two active groups, or show menu if more

GROUPS_FILE="/tmp/i3_groups.json"
ACTIVE_FILE="/tmp/i3_active_group"
HISTORY_FILE="/tmp/i3_group_history"

[[ ! -s "$GROUPS_FILE" ]] && { dunstify -u critical "No groups saved"; exit 1; }

CURRENT=$(cat "$ACTIVE_FILE" 2>/dev/null)
PREV=$(tail -2 "$HISTORY_FILE" 2>/dev/null | head -1)

# If we have history and prev group exists, toggle
if [[ -n "$PREV" && "$PREV" != "$CURRENT" ]]; then
    GROUP_EXISTS=$(jq -r --arg g "$PREV" 'has($g)' "$GROUPS_FILE")
    if [[ "$GROUP_EXISTS" == "true" ]]; then
        echo "$PREV" > "$ACTIVE_FILE"
        echo "$PREV" >> "$HISTORY_FILE"
        WCOUNT=$(jq -r --arg n "$PREV" '.[$n] | length' "$GROUPS_FILE")
        dunstify -u low -r 9911 "▶ $PREV ($WCOUNT windows)" -t 1200
        exit 0
    fi
fi

# Fallback: show rofi menu with all groups
ALL_GROUPS=$(jq -r 'keys[]' "$GROUPS_FILE")
[[ -z "$ALL_GROUPS" ]] && { dunstify -u critical "No groups saved"; exit 1; }

# Highlight current active
MENU=$(echo "$ALL_GROUPS" | while read -r n; do
    [[ "$n" == "$CURRENT" ]] && echo "▶ $n" || echo "  $n"
done)

PICKED=$(echo "$MENU" | rofi -dmenu -p "Switch to group:" -lines 5 -format s)
[[ -z "$PICKED" ]] && exit 0

NAME=$(echo "$PICKED" | sed 's/^[▶ ]*//')
echo "$NAME" > "$ACTIVE_FILE"
echo "$NAME" >> "$HISTORY_FILE"
WCOUNT=$(jq -r --arg n "$NAME" '.[$n] | length' "$GROUPS_FILE")
dunstify -u low -r 9911 "▶ $NAME ($WCOUNT windows)" -t 1200
