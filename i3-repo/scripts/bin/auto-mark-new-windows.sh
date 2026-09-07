#!/usr/bin/env bash
# auto-mark-new-windows.sh
#
# Daemon: watches i3 window events and auto-marks any new window that
# doesn't already have a real mark. Uses the same app→mark mapping as
# mark-unmarked.sh so that Slack always gets 's', notes get 'n', etc.
#
# Started via exec_always in i3 config.

SKIP_MARK="stale_loud"

# ── App → preferred mark mapping (keep in sync with mark-unmarked.sh) ─────────
MAPPINGS=(
    "slack:s"
    "sticky:n"
    "trilium:n"
    "gnote:n"
    "mousepad:n"
    "zettlr:n"
    "xmind:n"
    "tilix:t"
    "foot:t"
    "uxterm:t"
    "gnome-terminal:t"
    "kitty:t"
    "alacritty:t"
    "brave-browser:b"
    "brave:b"
    "firefox:f"
    "code:c"
    "code-oss:c"
    "vscodium:c"
    "zoom:z"
    "opera:o"
    "gmail:g"
    "nemo:m"
    "vlc:v"
    "celluloid:v"
    "obs:v"
    "gimp:o"
    "libreoffice:o"
    "chrome:b"
    "chromium:b"
    "telegram:s"
    "telegramdesktop:s"
    "discord:s"
    "whatsapp:w"
    "pavucontrol:u"
    "gnome-system-monitor:u"
    "htop:u"
)

_used_marks() {
    i3-msg -t get_tree 2>/dev/null | python3 -c "
import json, sys
def walk(n):
    for m in n.get('marks', []):
        print(m)
    for c in n.get('nodes', []) + n.get('floating_nodes', []):
        walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null
}

_window_info() {
    local cid="$1"
    i3-msg -t get_tree 2>/dev/null | python3 -c "
import json, sys
target = $cid
skip = '$SKIP_MARK'
def walk(n):
    if n.get('id') == target:
        real = [m for m in n.get('marks', []) if m != skip]
        wp   = n.get('window_properties', {})
        cls  = (wp.get('class',    '') or '').lower()
        inst = (wp.get('instance', '') or '').lower()
        print('marked=' + ('yes' if real else 'no'))
        print('class='  + cls)
        print('inst='   + inst)
        return
    for c in n.get('nodes', []) + n.get('floating_nodes', []):
        walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null
}

_preferred_letter() {
    local cls="$1"
    local inst="$2"
    for entry in "${MAPPINGS[@]}"; do
        local pat="${entry%%:*}"
        local letter="${entry##*:}"
        if [[ "$cls" == *"$pat"* || "$inst" == *"$pat"* ]]; then
            echo "$letter"
            return
        fi
    done
    echo ""
}

_next_slot_for() {
    local base="$1"
    local used="$2"
    if ! echo "$used" | grep -qx "$base"; then
        echo "$base"; return
    fi
    for digit in 1 2 3 4 5 6 7; do
        local slot="${base}${digit}"
        if ! echo "$used" | grep -qx "$slot"; then
            echo "$slot"; return
        fi
    done
    echo ""
}

_next_fallback_mark() {
    local used="$1"
    local ALPHABET=(z y x w v u t s r q p o n m l k j i h g f e d c b a)
    for letter in "${ALPHABET[@]}"; do
        local slot
        slot=$(_next_slot_for "$letter" "$used")
        [ -n "$slot" ] && echo "$slot" && return
    done
    echo ""
}

# Kill any previous instance of this script
PIDFILE="/tmp/auto-mark-new-windows.pid"
if [ -f "$PIDFILE" ]; then
    old_pid=$(cat "$PIDFILE")
    kill "$old_pid" 2>/dev/null
fi
echo $$ > "$PIDFILE"

# ── event loop ────────────────────────────────────────────────────────────────
i3-msg -t subscribe '["window"]' | \
jq -r --unbuffered 'select(.change == "new") | .container.id' | \
while read -r cid; do
    [ -z "$cid" ] && continue

    # Small delay to let the window settle and get its WM_CLASS set
    sleep 0.3

    info=$(_window_info "$cid")
    [ -z "$info" ] && continue

    marked=$(echo "$info" | grep '^marked=' | cut -d= -f2)
    cls=$(echo    "$info" | grep '^class='  | cut -d= -f2)
    inst=$(echo   "$info" | grep '^inst='   | cut -d= -f2)

    # Already marked by launch-and-mark.sh or manually — skip
    [ "$marked" = "yes" ] && continue

    used=$(_used_marks)
    preferred=$(_preferred_letter "$cls" "$inst")

    if [ -n "$preferred" ]; then
        mark=$(_next_slot_for "$preferred" "$used")
        [ -z "$mark" ] && mark=$(_next_fallback_mark "$used")
    else
        mark=$(_next_fallback_mark "$used")
    fi

    [ -z "$mark" ] && continue

    i3-msg "[con_id=\"$cid\"] mark --add \"$mark\"" >/dev/null 2>&1
    dunstify -u low -t 2000 "🏷️ Auto-marked: $mark ($cls)"
done
