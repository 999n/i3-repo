#!/bin/bash
# Toggle polybar: if autohide is running, kill it and show bar permanently.
# If bar is pinned (no autohide), restart autohide.

PIDFILE=/tmp/polybar-autohide.pid

if [ -f "$PIDFILE" ] && kill -0 "$(cat $PIDFILE)" 2>/dev/null; then
    # autohide is running — kill it and pin the bar visible
    kill "$(cat $PIDFILE)"
    rm -f "$PIDFILE"
    polybar-msg cmd show
else
    # bar is pinned — restart autohide
    ~/.config/polybar/autohide.sh &
    echo $! > "$PIDFILE"
fi
