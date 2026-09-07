#!/bin/bash

WINDOW_ID=$(xdotool getactivewindow)

# Use 'id' not 'con_id' for X11 window IDs
RESULT=$(i3-msg "[id=$WINDOW_ID] unmark" 2>&1)

if echo "$RESULT" | grep -q '"success":true'; then
    dunstify -u low -t 10"🗑️ Window unmarked"
else
    dunstify -u low "⚠️ No marks on this window"
fi