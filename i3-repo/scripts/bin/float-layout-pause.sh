#!/bin/bash
LOCK=/tmp/float-layout-paused
if [ -f "$LOCK" ]; then
  rm "$LOCK"
  rm -f /tmp/float-manual-sizes
  dunstify -u low -t 1500 "Float layout: resumed (sizes reset)"
else
  touch "$LOCK"
  dunstify -u low -t 1500 "Float layout: paused — drag/resize freely"
fi
