#!/bin/bash
# Toggle the currently focused window in/out of a quick slot.
# Usage: group-toggle-window.sh <slot_number>

GROUPS_FILE="/tmp/i3_groups.json"
ACTIVE_FILE="/tmp/i3_active_group"
HISTORY_FILE="/tmp/i3_group_history"

SLOT="$1"
[[ -z "$SLOT" ]] && { dunstify -u critical "Usage: group-toggle-window.sh <slot>"; exit 1; }

GROUP_NAME="@quick$SLOT"
[[ ! -s "$GROUPS_FILE" ]] && echo '{}' > "$GROUPS_FILE"

# 1. Get the focused window node
FOCUSED_NODE=$(i3-msg -t get_tree | jq -c 'recurse(.nodes[]?, .floating_nodes[]?) | select(type == "object" and .focused == true)')
[[ -z "$FOCUSED_NODE" ]] && { dunstify -u critical "No focused window found"; exit 1; }

# 2. Extract mark and name
FOCUSED_MARK=$(echo "$FOCUSED_NODE" | jq -r '.marks[0] // empty')
# We don't want to use sed because name might not have quotes. However, jq already returns string without outer quotes when using -r, but inner quotes might be an issue if we re-json it. We can just use the jq output.
FOCUSED_NAME=$(echo "$FOCUSED_NODE" | jq -r '.name')

# 3. If window has no mark, generate a hidden/auto one and apply it instantly
if [[ -z "$FOCUSED_MARK" ]]; then
    # Generate timestamp-based mark, suffix with random digits to avoid collisions
    FOCUSED_MARK="qm_$(date +%s)_$RANDOM"
    i3-msg mark "$FOCUSED_MARK" > /dev/null
fi

# 4. Check if the window is already in the group
IN_GROUP=$(jq -r --arg g "$GROUP_NAME" --arg m "$FOCUSED_MARK" '.[$g] // [] | map(select(.mark == $m)) | length' "$GROUPS_FILE")

if [[ "$IN_GROUP" -gt 0 ]]; then
    # It's in the group, remove it
    jq --arg g "$GROUP_NAME" --arg m "$FOCUSED_MARK" '.[$g] |= map(select(.mark != $m))' "$GROUPS_FILE" > "$GROUPS_FILE.tmp" && mv "$GROUPS_FILE.tmp" "$GROUPS_FILE"
    dunstify -u low -r 9912 "➖ Removed from Quick $SLOT" -t 800
else
    # It's not in the group, add it
    jq --arg g "$GROUP_NAME" --arg m "$FOCUSED_MARK" --arg n "$FOCUSED_NAME" '.[$g] = ((.[$g] // []) + [{mark: $m, name: $n}])' "$GROUPS_FILE" > "$GROUPS_FILE.tmp" && mv "$GROUPS_FILE.tmp" "$GROUPS_FILE"
    TOTAL=$(jq -r --arg g "$GROUP_NAME" '.[$g] | length' "$GROUPS_FILE")
    dunstify -u low -r 9912 "➕ Added to Quick $SLOT ($TOTAL windows)" -t 800
fi

exit 0
