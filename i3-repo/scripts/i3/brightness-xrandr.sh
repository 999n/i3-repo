#!/bin/bash
OUTPUT="eDP1"
CURRENT=$(xrandr --verbose | grep -A5 "$OUTPUT" | grep Brightness | awk '{print $2}')
NEW=$(echo "$CURRENT $1 0.1" | awk '{printf "%.1f", $1 + ($2=="up" ? $3 : -$3)}')
NEW=$(echo "$NEW" | awk '{if($1>1.0) print 1.0; else if($1<0.1) print 0.1; else print $1}')
xrandr --output "$OUTPUT" --brightness "$NEW"
