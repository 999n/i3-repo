#!/usr/bin/env bash
# focus-mark-watcher.sh — IMPROVED VERSION
# On focus change: if the new window has a mark, show it as a subtle notification.
# Uses dunstify for a polished, non-intrusive notification instead of osd_cat overlay.

SKIP_MARKS="stale_loud"
NOTIFICATION_ID=9999  # Use fixed ID to replace previous notification
DURATION_MS=1500      # Show for 1.5 seconds (reduced from 2s)

# Single instance guard
PIDFILE="/tmp/.focus-mark-watcher.pid"
if [[ -f "$PIDFILE" ]]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
fi
echo $$ > "$PIDFILE"

show_mark() {
    local mark="$1"
    # Use dunstify for a subtle notification instead of full-screen overlay
    dunstify -u low -t "$DURATION_MS" -r "$NOTIFICATION_ID" \
        -a "i3mark" \
        "Mark" "$mark"
}

i3-msg -t subscribe '["window"]' -m | while IFS= read -r line; do
    # Only focus events
    change=$(python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('change',''))
except: pass
" <<< "$line" 2>/dev/null)
    [[ "$change" != "focus" ]] && continue

    # Read marks directly from the event payload — no extra get_tree call needed
    mark=$(python3 -c "
import json,sys
skip = set('${SKIP_MARKS}'.split(','))
try:
    c = json.load(sys.stdin).get('container', {})
    marks = [m for m in c.get('marks', []) if m not in skip and m]
    if marks:
        marks.sort(key=lambda m: (len(m), m))
        print(marks[0])
except: pass
" <<< "$line" 2>/dev/null)

    [[ -z "$mark" ]] && continue
    show_mark "$mark"
done
