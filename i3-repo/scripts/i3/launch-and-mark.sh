#!/usr/bin/env bash

LETTER="$1"
CMD="$2"
NOTIFY="${3:-}"

# ── helpers ────────────────────────────────────────────────────────────────────

_all_window_ids() {
    i3-msg -t get_tree | python3 -c "
import json, sys
def walk(n):
    if n.get('window'): print(n['id'])
    for c in n.get('nodes',[]) + n.get('floating_nodes',[]): walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null
}

_used_marks() {
    i3-msg -t get_tree | python3 -c "
import json, sys
def walk(n):
    for m in n.get('marks',[]): print(m)
    for c in n.get('nodes',[]) + n.get('floating_nodes',[]): walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null
}

_marks_of() {
    local wid="$1"
    i3-msg -t get_tree | python3 -c "
import json, sys
target=$wid
def walk(n):
    if n.get('id')==target:
        print(json.dumps(n.get('marks',[])))
        return
    for c in n.get('nodes',[]) + n.get('floating_nodes',[]): walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null
}

# Next free slot for this letter: letter, letter1 .. letter7
_next_mark() {
    local base="$1"
    local used
    used=$(_used_marks)
    echo "$used" | grep -qx "$base"  || { echo "$base";  return; }
    for i in 1 2 3 4 5 6 7; do
        echo "$used" | grep -qx "${base}${i}" || { echo "${base}${i}"; return; }
    done
    echo ""
}

# ── main ───────────────────────────────────────────────────────────────────────

before=$(_all_window_ids | sort)

eval "$CMD" &

[[ -n "$NOTIFY" ]] && dunstify -u low "$NOTIFY"

# Poll up to 8 s for the new window
new_id=""
for _ in $(seq 1 40); do
    sleep 0.2
    after=$(_all_window_ids | sort)
    new_id=$(comm -13 <(echo "$before") <(echo "$after") | head -1)
    [[ -n "$new_id" ]] && break
done

[[ -z "$new_id" ]] && exit 0

# Don't touch already-marked windows
marks_json=$(_marks_of "$new_id")
has_mark=$(python3 -c "import json,sys; print('yes' if json.loads('${marks_json//\'/\"}') else 'no')" 2>/dev/null)
[[ "$has_mark" == "yes" ]] && exit 0

mark=$(_next_mark "$LETTER")
if [[ -z "$mark" ]]; then
    dunstify -u normal "⚠️ Auto-mark: all slots ${LETTER}–${LETTER}7 are in use"
    exit 0
fi

i3-msg "[con_id=\"$new_id\"] mark --add \"$mark\"" > /dev/null
dunstify -u low "🏷️ Auto-marked: $mark"
