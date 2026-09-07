#!/bin/bash
set -euo pipefail
SPOTS="$HOME/.local/share/keynav/spots.conf"

[[ ! -s "$SPOTS" ]] && notify-send "keynav" "No spots to delete." -t 1500 && exit 1

CHOICE=$(awk '{print $1 " (" $5 ")"}' "$SPOTS" | rofi -dmenu -p "Delete spot:") || exit 0
[[ -z "$CHOICE" ]] && exit 0

SPOT_NAME=$(echo "$CHOICE" | awk '{print $1}')

grep -v "^$SPOT_NAME " "$SPOTS" > "$SPOTS.tmp"
mv "$SPOTS.tmp" "$SPOTS"

notify-send "keynav" "Deleted: $SPOT_NAME" -t 1200
