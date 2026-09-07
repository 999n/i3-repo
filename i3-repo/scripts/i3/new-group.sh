#!/bin/bash
# Simple group creator - pick marked windows, name the group

GROUPS_FILE="/tmp/i3_groups.json"
ACTIVE_FILE="/tmp/i3_active_group"

[[ ! -s "$GROUPS_FILE" ]] && echo '{}' > "$GROUPS_FILE"

# Get all marked windows
all_marked=$(i3-msg -t get_tree | jq -r '[recurse | objects | select(.marks != null and (.marks | length) > 0) | select(.marks[] != "stale_loud") | {id: .id, name: .name, mark: .marks[0]}]')

count=$(echo "$all_marked" | jq 'length')
[[ $count -eq 0 ]] && { dunstify -u critical "No marked windows"; exit 1; }

# Show marked windows for multi-select
marked_list=$(echo "$all_marked" | jq -r '.[] | "\(.mark) - \(.name)"')

# User picks which ones to include
selected=$(echo "$marked_list" | rofi -dmenu -p "Pick windows for group:" -multi-select 2>/dev/null)
[[ -z "$selected" ]] && exit 0

# Convert selected marks back to window objects
selected_marks=$(echo "$selected" | sed 's/ -.*//' | tr '\n' '|' | sed 's/|$//')
windows=$(echo "$all_marked" | jq --arg marks "$selected_marks" '[.[] | select(.mark | test($marks))]')

count=$(echo "$windows" | jq 'length')
[[ $count -eq 0 ]] && { dunstify -u critical "No windows selected"; exit 1; }

# Ask for group name
group_name=$(echo "" | rofi -dmenu -p "Group name:" -lines 0 2>/dev/null)
group_name=$(echo "$group_name" | xargs)
[[ -z "$group_name" ]] && exit 0

# Save group
groups=$(cat "$GROUPS_FILE")
groups=$(echo "$groups" | jq --arg n "$group_name" --argjson w "$windows" '.[$n] = $w')
echo "$groups" > "$GROUPS_FILE"
echo "$group_name" > "$ACTIVE_FILE"

dunstify -u low "✅ Group '$group_name' saved ($count windows) - ACTIVE"
