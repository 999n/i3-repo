#!/usr/bin/env bash
# Usage: keynav-monitor.sh <x> <y>
# Warps mouse to (x,y) and starts keynav grid on that monitor.
# Uses a verify-loop so we don't race with xdotool.

set -e

TARGET_X=$1
TARGET_Y=$2

if [[ -z "$TARGET_X" || -z "$TARGET_Y" ]]; then
    echo "Usage: $0 <x> <y>" >&2
    exit 1
fi

# Kill any existing keynav daemon so it doesn't fight us for grabs
pkill -x keynav 2>/dev/null || true
sleep 0.05

# Move mouse and block until X confirms the pointer is at the target.
# --sync in xdotool only waits for the XWarpPointer request to be sent;
# xdotool getmouselocation --shell is our actual confirmation.
xdotool mousemove --sync "$TARGET_X" "$TARGET_Y"

# Busy-wait up to 500ms for pointer to actually arrive
for i in $(seq 1 50); do
    eval "$(xdotool getmouselocation --shell 2>/dev/null)"
    if [[ "$X" -eq "$TARGET_X" && "$Y" -eq "$TARGET_Y" ]]; then
        break
    fi
    sleep 0.01
done

# Now launch keynav. It will call query_current_screen() which reads
# the pointer — which is now on the correct monitor.
# We pass the full startup config inline so no daemon race is possible.
exec keynav 'start,grid 1x1,warp'
