#!/bin/bash
# Edit a group - pick which windows to keep/add

GROUPS_FILE="/tmp/i3_groups.json"

[[ ! -s "$GROUPS_FILE" ]] && { dunstify -u critical "No groups saved"; exit 1; }

# List groups
GROUPS=$(cat "$GROUPS_FILE" | jq -r 'keys[]')
[[ -z "$GROUPS" ]] && { dunstify -u critical "No groups to edit"; exit 1; }

# Pick group to edit
GROUP_NAME=$(echo "$GROUPS" | rofi -dmenu -p "Edit group:")
[[ -z "$GROUP_NAME" ]] && exit 0

# Get current windows in this group
CURRENT=$(cat "$GROUPS_FILE" | jq ".\"$GROUP_NAME\"")
dunstify -u low "Current windows in '$GROUP_NAME': $(echo "$CURRENT" | jq -r '.[].name' | tr '\n' ', ')" -t 3000

# Get all marked windows now
WINDOWS=$(i3-msg -t get_tree | jq -r '[recurse | objects | select(.marks != null and (.marks | length) > 0) | select(.marks[] != "stale_loud") | {id: .id, name: .name}]')

COUNT=$(echo "$WINDOWS" | jq 'length')
[[ $COUNT -eq 0 ]] && { dunstify -u critical "No marked windows to add"; exit 1; }

# Update group with new windows
GROUPS=$(cat "$GROUPS_FILE")
GROUPS=$(echo "$GROUPS" | jq --arg name "$GROUP_NAME" --argjson windows "$WINDOWS" '.[$name] = $windows')
echo "$GROUPS" > "$GROUPS_FILE"

dunstify -u low "✅ Updated group '$GROUP_NAME' ($COUNT windows)"
