#!/bin/bash
set -euo pipefail
SPOTS="$HOME/.local/share/keynav/spots.conf"

[[ ! -s "$SPOTS" ]] && notify-send "keynav" "No spots yet. Use c to mark." -t 1500 && exit 1

# Build rofi list: "spot name  (class)"
CHOICE=$(awk -F'|' '{print $1 "  (" $5 ")"}' "$SPOTS" \
    | rofi -dmenu -p "Jump to:") || exit 0
[[ -z "$CHOICE" ]] && exit 0

# Extract spot name (everything before the trailing "  (class)")
SPOT_NAME=$(echo "$CHOICE" | sed 's/  ([^)]*)$//')

LINE=$(grep "^${SPOT_NAME}|" "$SPOTS") || {
    notify-send "keynav" "Spot not found: $SPOT_NAME" -t 1200
    exit 1
}

WIN=$(  echo "$LINE" | cut -d'|' -f2)
PCT_X=$(echo "$LINE" | cut -d'|' -f3)
PCT_Y=$(echo "$LINE" | cut -d'|' -f4)
CLASS=$(echo "$LINE" | cut -d'|' -f5)

# Keep a copy of the original ID so we can rewrite it if we find a replacement
ORIGINAL_WIN="$WIN"

# Verify the window still exists, or fall back to another instance
if ! xdotool getwindowname "$WIN" &>/dev/null; then
    replacement=""

    if candidate=$(xdotool getactivewindow 2>/dev/null); then
        active_class=$(xdotool getwindowclassname "$candidate" 2>/dev/null || true)
        if [[ "$active_class" == "$CLASS" ]]; then
            replacement="$candidate"
        fi
    fi

    if [[ -z "$replacement" ]] && candidate=$(xdotool search --onlyvisible --classname "$CLASS" 2>/dev/null | head -n1); then
        replacement="$candidate"
    fi

    if [[ -z "$replacement" ]] && candidate=$(xdotool search --classname "$CLASS" 2>/dev/null | head -n1); then
        replacement="$candidate"
    fi

    if [[ -z "$replacement" ]]; then
        notify-send "keynav" "$CLASS window is closed — remark it." -t 1800
        exit 1
    fi

    WIN="$replacement"
    notify-send "keynav" "Reusing reopened $CLASS window for $SPOT_NAME" -t 1400

    awk -F'|' -v name="$SPOT_NAME" -v win="$WIN" 'BEGIN {OFS=FS} $1==name {$2=win} {print}' "$SPOTS" > "$SPOTS.tmp"
    mv "$SPOTS.tmp" "$SPOTS"
fi

# Switch to window's workspace AND raise it (works across all workspaces)
wmctrl -ia "$WIN"
sleep 0.2

# Get CURRENT window geometry after raise (position + size, post-resize safe)
GEOM=$(xdotool getwindowgeometry "$WIN")
WIN_X=$(echo "$GEOM" | grep Position | awk '{print $2}' | cut -d, -f1)
WIN_Y=$(echo "$GEOM" | grep Position | awk '{print $2}' | cut -d, -f2)
WIN_W=$(echo "$GEOM" | grep Geometry | awk '{print $2}' | cut -dx -f1)
WIN_H=$(echo "$GEOM" | grep Geometry | awk '{print $2}' | cut -dx -f2)

# Recompute absolute coords from saved percentages × current window size
ABS_X=$(awk "BEGIN {printf \"%d\", $WIN_X + ($PCT_X * $WIN_W)}")
ABS_Y=$(awk "BEGIN {printf \"%d\", $WIN_Y + ($PCT_Y * $WIN_H)}")

xdotool mousemove "$ABS_X" "$ABS_Y"
xdotool click 1
