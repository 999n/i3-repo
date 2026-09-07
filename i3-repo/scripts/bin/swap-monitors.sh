#!/usr/bin/env bash
# swap-monitors.sh
# Swaps all workspaces between eDP1 and HDMI2.
# Preserves focus on whichever workspace was focused before.

LEFT="eDP1"
RIGHT="HDMI2"

# Get full workspace list as JSON
WORKSPACES=$(i3-msg -t get_workspaces)

# Focused workspace name (to restore focus at the end)
FOCUSED=$(echo "$WORKSPACES" | python3 -c "
import sys, json
ws = json.load(sys.stdin)
for w in ws:
    if w['focused']:
        print(w['name'])
        break
")

# Move all workspaces on LEFT → RIGHT first (into a temp holding pattern)
# then all on RIGHT → LEFT, then temp → RIGHT.
# Simpler: move LEFT→RIGHT, then RIGHT→LEFT in one pass using the snapshot.

LEFT_WS=$(echo "$WORKSPACES" | python3 -c "
import sys, json
ws = json.load(sys.stdin)
for w in ws:
    if w['output'] == '$LEFT':
        print(w['name'])
")

RIGHT_WS=$(echo "$WORKSPACES" | python3 -c "
import sys, json
ws = json.load(sys.stdin)
for w in ws:
    if w['output'] == '$RIGHT':
        print(w['name'])
")

# Move LEFT workspaces → RIGHT
while IFS= read -r ws; do
    [ -z "$ws" ] && continue
    i3-msg "workspace \"$ws\"; move workspace to output $RIGHT" >/dev/null
done <<< "$LEFT_WS"

# Move RIGHT workspaces (original) → LEFT
while IFS= read -r ws; do
    [ -z "$ws" ] && continue
    i3-msg "workspace \"$ws\"; move workspace to output $LEFT" >/dev/null
done <<< "$RIGHT_WS"

# Restore focus
if [ -n "$FOCUSED" ]; then
    i3-msg "workspace \"$FOCUSED\"" >/dev/null
fi
