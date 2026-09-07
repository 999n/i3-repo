#!/usr/bin/env bash
# mark-unmarked.sh
#
# Assign marks to every window that has no real mark (stale_loud doesn't count).
# Priority:
#   1. Check app class / instance against the mapping table → assign preferred letter
#   2. If no mapping match, assign next free slot from z downward (fallback)
#
# Run on demand via Mod4+F10

SKIP_MARK="stale_loud"
ALPHABET=(z y x w v u t s r q p o n m l k j i h g f e d c b a)

# ── App → preferred mark mapping ─────────────────────────────────────────────
# Format: "pattern:mark"  (pattern matched case-insensitively against class or instance)
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

TREE=$(i3-msg -t get_tree 2>/dev/null)

# All marks currently in use
_used_marks() {
    echo "$TREE" | python3 -c "
import json, sys
def walk(n):
    for m in n.get('marks', []):
        print(m)
    for c in n.get('nodes', []) + n.get('floating_nodes', []):
        walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null
}

# Print lines: con_id CLASS INSTANCE  for every window without a real mark
_unmarked_windows() {
    local skip="$SKIP_MARK"
    echo "$TREE" | python3 -c "
import json, sys
skip = '$skip'
def walk(n):
    if n.get('window') is not None:
        real = [m for m in n.get('marks', []) if m != skip]
        if not real:
            wp = n.get('window_properties', {})
            cls  = (wp.get('class',    '') or '').lower()
            inst = (wp.get('instance', '') or '').lower()
            print(str(n['id']) + ' ' + cls + ' ' + inst)
    for c in n.get('nodes', []) + n.get('floating_nodes', []):
        walk(c)
walk(json.load(sys.stdin))
" 2>/dev/null
}

# Given class and instance, return preferred letter or ""
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

# Next free slot for a given base letter; pass current used-marks string
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

# Next free slot from z downward (fallback for unknown apps)
_next_fallback_mark() {
    local used="$1"
    for letter in "${ALPHABET[@]}"; do
        local slot
        slot=$(_next_slot_for "$letter" "$used")
        [ -n "$slot" ] && echo "$slot" && return
    done
    echo ""
}

# ── main ──────────────────────────────────────────────────────────────────────

unmarked=$(_unmarked_windows)
[ -z "$unmarked" ]

used=$(_used_marks)
count=0

while IFS=' ' read -r cid cls inst; do
    [ -z "$cid" ] && continue

    # Try preferred letter from app mapping
    preferred=$(_preferred_letter "$cls" "$inst")

    if [ -n "$preferred" ]; then
        mark=$(_next_slot_for "$preferred" "$used")
        # If preferred letter is full, fall back to generic
        [ -z "$mark" ] && mark=$(_next_fallback_mark "$used")
    else
        mark=$(_next_fallback_mark "$used")
    fi

    if [ -z "$mark" ]; then
        dunstify -u normal "⚠️ mark-unmarked: all slots exhausted!"
        break
    fi

    i3-msg "[con_id=\"$cid\"] mark --add \"$mark\"" >/dev/null 2>&1
    used=$(printf "%s\n%s" "$used" "$mark")
    count=$((count + 1))
done <<< "$unmarked"

[ "$count" -gt 0 ] && dunstify -u low "🏷️ Marked $count window(s)"
