#!/bin/bash
# Switches to a quick group and activates its next window
# Usage: group-switch.sh <slot>

GROUPS_FILE="/tmp/i3_groups.json"
ACTIVE_FILE="/tmp/i3_active_group"
HISTORY_FILE="/tmp/i3_group_history"

SLOT="$1"
[[ -z "$SLOT" ]] && { dunstify -u critical "Usage: group-switch.sh <slot>"; exit 1; }

GROUP_NAME="@quick$SLOT"
[[ ! -s "$GROUPS_FILE" ]] && echo '{}' > "$GROUPS_FILE"

# Clean up dead windows (windows that were closed)
ACTIVE_MARKS=$(i3-msg -t get_marks 2>/dev/null || echo "[]")
jq --argjson am "$ACTIVE_MARKS" 'map_values(map(select(.mark as $m | $am | index($m))))' "$GROUPS_FILE" > "${GROUPS_FILE}.tmp" && mv "${GROUPS_FILE}.tmp" "$GROUPS_FILE"

# Check if group exists and has windows
TOTAL=$(jq -r --arg g "$GROUP_NAME" '.[$g] | length' "$GROUPS_FILE" 2>/dev/null)
if [[ "$TOTAL" == "0" ]] || [[ "$TOTAL" == "null" ]] || [[ -z "$TOTAL" ]]; then
    dunstify -u low -r 9911 "ℹ️ Quick slot $SLOT is empty" -t 1000
    exit 0
fi

# Activate the group
echo "$GROUP_NAME" > "$ACTIVE_FILE"
echo "$GROUP_NAME" >> "$HISTORY_FILE"

# Fire group-next to bring windows to focus
~/.config/i3/group-next.sh
