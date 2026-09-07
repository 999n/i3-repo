#!/bin/bash
killall -q polybar autohide.sh
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

if type "xrandr" > /dev/null 2>&1; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar --reload freeman &
    done
else
    polybar --reload freeman &
fi
sleep 5
