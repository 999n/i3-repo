#!/bin/bash
# Cycle: NORMAL → FULLSCREEN_TILED → HIDDEN (tiled off-screen via massive gaps) → NORMAL

STATE=/tmp/fullfull_state
state=$(cat "$STATE" 2>/dev/null || echo "NORMAL")

if [ "$state" = "NORMAL" ]; then
    i3-msg "gaps right current set 0; gaps left current set 0; gaps top current set 0; gaps bottom current set 29" >/dev/null
    echo "FULLSCREEN_TILED" > "$STATE"
    dunstify -u low -t 1200 "🖥️ fullscreen tiled"

elif [ "$state" = "FULLSCREEN_TILED" ]; then
    i3-msg "gaps right current set 9999; gaps left current set 9999; gaps top current set 9999; gaps bottom current set 9999" >/dev/null
    echo "HIDDEN" > "$STATE"
    dunstify -u low -t 1200 "🫥 tiled hidden"

else
    i3-msg "gaps right current set 600; gaps left current set 10; gaps top current set 0; gaps bottom current set 29" >/dev/null
    echo "NORMAL" > "$STATE"
    dunstify -u low -t 1200 "↩️ normal"
fi
