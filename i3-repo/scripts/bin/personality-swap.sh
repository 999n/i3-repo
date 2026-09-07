#!/bin/bash
# personality-swap.sh — toggle bars hidden/visible

STATE=/tmp/i3-personality

if [ "$(cat "$STATE" 2>/dev/null)" = "deep" ]; then
  i3-msg "bar mode dock bar-0; bar mode dock bar-1" >/dev/null
  echo "normal" > "$STATE"
  dunstify -u low -t 1000 "bars: on"
else
  i3-msg "bar mode invisible bar-0; bar mode invisible bar-1" >/dev/null
  echo "deep" > "$STATE"
  dunstify -u low -t 1000 "bars: hidden"
fi
