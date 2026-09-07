#!/usr/bin/env bash
# i3-marks-rofi.sh
# Shows all marked i3 windows in rofi. Selecting one focuses it.
# Skips internal marks (stale_loud).
# One entry per mark for exact matching.

SKIP="stale_loud"

# Parse tree with python — creates one entry per mark
entries=$(i3-msg -t get_tree | python3 -c "
import json, sys

skip = '$SKIP'

def walk(n):
    if n.get('window') is not None:
        real = [m for m in n.get('marks', []) if m != skip]
        if real:
            title = (n.get('name') or '(no title)')[:60]
            for mark in sorted(real):
                print(f'{mark}\t{title}\t{n[\"id\"]}')
    for c in n.get('nodes', []) + n.get('floating_nodes', []):
        walk(c)

walk(json.load(sys.stdin))
" 2>/dev/null | sort -t$'\t' -k1,1)

if [[ -z "$entries" ]]; then
    rofi -e "No marked windows found."
    exit 0
fi

display_lines=()
window_ids=()

while IFS=$'\t' read -r mark title cid; do
    display_lines+=("${mark}  ${title}")
    window_ids+=("${cid}")
done <<< "$entries"

chosen=$(printf '%s\n' "${display_lines[@]}" \
    | rofi -dmenu -i -p "🏷 Marks" -format i \
           -theme-str 'listview { lines: 15; }')

[[ -z "$chosen" ]] && exit 0

selected_id="${window_ids[$chosen]}"
i3-msg "[con_id=${selected_id}] focus" >/dev/null
