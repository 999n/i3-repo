#!/bin/bash
# clip-daemon.sh — watch clipboard and append new entries to history
HIST="/tmp/clip-history"
touch "$HIST"
LAST=""
while sleep 0.5; do
  CURR=$(xclip -selection clipboard -o 2>/dev/null | head -c 200 | tr '\n' ' ')
  [ -z "$CURR" ] || [ "$CURR" = "$LAST" ] && continue
  LAST="$CURR"
  { echo "$CURR"; cat "$HIST"; } | head -100 > "${HIST}.tmp"
  mv "${HIST}.tmp" "$HIST"
done
