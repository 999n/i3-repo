#!/usr/bin/env bash
# show-focused-mark.sh — manually show the mark of the focused window

SKIP_MARKS="stale_loud"

mark=$(i3-msg -t get_tree | python3 -c "
import json, sys
skip = set('${SKIP_MARKS}'.split(','))
def walk(n):
    if n.get('focused'):
        if n.get('window') is None:
            return
        real = [m for m in n.get('marks', []) if m not in skip and m]
        if real:
            real.sort(key=lambda m: (len(m), m))
            print(real[0])
        return
    for c in n.get('nodes', []) + n.get('floating_nodes', []):
        walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null)

pkill -f osd_cat 2>/dev/null

if [[ -n "$mark" ]]; then
    echo "$mark" | DISPLAY="${DISPLAY:-:0}" osd_cat \
        --font="-*-fixed-bold-r-*-*-72-*-*-*-*-*-*-*" \
        --color=white \
        --outline=3 \
        --outlinecolour=black \
        --pos=middle \
        --align=center \
        --offset=0 \
        --indent=0 \
        --delay=2 &
else
    echo "no mark" | DISPLAY="${DISPLAY:-:0}" osd_cat \
        --font="-*-fixed-bold-r-*-*-24-*-*-*-*-*-*-*" \
        --color=gray \
        --pos=middle \
        --align=center \
        --delay=1 &
fi
