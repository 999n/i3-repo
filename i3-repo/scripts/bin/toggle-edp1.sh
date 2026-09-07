#!/bin/bash
if xrandr | grep "eDP1 connected" | grep -q " [0-9]"; then
    xrandr --output eDP1 --off
else
    xrandr --output eDP1 --mode 1920x1080 --pos 1920x0
fi
