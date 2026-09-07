#!/bin/bash
# tiled-expose.sh — expose tiled windows on the current workspace in a grid.
# Press Mod4+g again to cancel. Click/focus a window to jump to it and restore.

STATE=/tmp/tiled-expose-state
HOOK=/tmp/tiled-expose-hook
LAYOUT_DIR=/tmp/tiled-expose-layouts

GAP=6
BAR_TOP=0
BAR_BOT=23

# ─── RESTORE ──────────────────────────────────────────────────────────────────
do_restore() {
    # Kill the focus-watcher subprocess
    [ -f "$HOOK" ] && kill "$(cat "$HOOK")" 2>/dev/null
    rm -f "$HOOK"

    CUR_WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

    # Restore layout via i3-resurrect if a saved layout exists
    layout_file="$LAYOUT_DIR/ws_${CUR_WS}_layout.json"
    if [ -f "$layout_file" ]; then
        i3-resurrect restore -w "$CUR_WS" --layout-only -d "$LAYOUT_DIR" 2>/dev/null
        sleep 0.2
    fi

    # Fallback: un-float anything resurrect missed
    while IFS='|' read -r con_id _rest; do
        state=$(i3-msg -t get_tree | jq -r --argjson id "$con_id" \
            '.. | objects | select(.id? == $id) | .floating?' 2>/dev/null)
        [ "$state" = "user_on" ] && \
            i3-msg "[con_id=$con_id] floating disable" >/dev/null 2>&1
    done < "$STATE"

    rm -f "$STATE"
    rm -rf "$LAYOUT_DIR"
}

# Second press → cancel and restore
if [ -f "$STATE" ]; then
    do_restore
    exit 0
fi

# ─── COLLECT ──────────────────────────────────────────────────────────────────
TREE=$(i3-msg -t get_tree)
CUR_WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

# Physical screen rect for the focused output
read -r OX OY OW OH < <(echo "$TREE" | jq -r '
  .. | objects
  | select(.type? == "output" and .name? != "__i3")
  | select(.. | objects | select(.focused? == true) | .id? != null)
  | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"
' | head -1)
[ -z "$OW" ] && OX=0 && OY=0 && OW=1920 && OH=1080

ZX=$OX
ZY=$(( OY + BAR_TOP ))
ZW=$OW
ZH=$(( OH - BAR_TOP - BAR_BOT ))

# All tiled (non-floating) windows on the current workspace
mapfile -t ENTRIES < <(echo "$TREE" | jq -r --arg ws "$CUR_WS" '
  .. | objects
  | select(.type? == "workspace" and .name? == $ws)
  | .. | objects
  | select(.window != null)
  | select(.floating? != "user_on" and .floating? != "auto_on")
  | "\(.id)|\(.name // "")"
' 2>/dev/null)

N=${#ENTRIES[@]}
[ "$N" -eq 0 ] && dunstify -u low -t 2000 "tiled-expose" "No tiled windows on this workspace." && exit 0

# ─── SAVE STATE ───────────────────────────────────────────────────────────────
> "$STATE"
for entry in "${ENTRIES[@]}"; do
    printf '%s\n' "$entry" >> "$STATE"
done

mkdir -p "$LAYOUT_DIR"
i3-resurrect save -w "$CUR_WS" --layout-only -d "$LAYOUT_DIR" 2>/dev/null

# i3-resurrect names the file with "workspace_" prefix — normalise it
src="$LAYOUT_DIR/workspace_${CUR_WS}_layout.json"
dst="$LAYOUT_DIR/ws_${CUR_WS}_layout.json"
[ -f "$src" ] && mv "$src" "$dst"

# ─── GRID MATH ────────────────────────────────────────────────────────────────
COLS=$(echo "sqrt($N)" | bc)
(( COLS < 1 )) && COLS=1
ROWS=$(( (N + COLS - 1) / COLS ))
# Ensure the grid actually fits all windows
(( COLS * ROWS < N )) && COLS=$(( COLS + 1 )) && ROWS=$(( (N + COLS - 1) / COLS ))

CW=$(( (ZW - GAP * (COLS + 1)) / COLS ))
CH=$(( (ZH - GAP * (ROWS + 1)) / ROWS ))
[ "$CW" -lt 100 ] && CW=100
[ "$CH" -lt 80  ] && CH=80

# ─── FLOAT + POSITION ─────────────────────────────────────────────────────────
IDX=0
for entry in "${ENTRIES[@]}"; do
    con_id=$(echo "$entry" | awk -F'|' '{print $1}')

    COL=$(( IDX % COLS ))
    ROW=$(( IDX / COLS ))
    TX=$(( ZX + GAP + COL * (CW + GAP) ))
    TY=$(( ZY + GAP + ROW * (CH + GAP) ))

    i3-msg "[con_id=$con_id] floating enable, resize set $CW $CH, move position $TX $TY" >/dev/null 2>&1
    IDX=$(( IDX + 1 ))
done

# ─── FOCUS WATCHER ────────────────────────────────────────────────────────────
# Watches for a focus change — when the user clicks a window, restore and jump to it.
(
    sleep 0.5
    BEFORE=$(i3-msg -t get_tree | jq -r '.. | objects | select(.focused? == true) | .id' | head -1)

    while true; do
        sleep 0.12
        [ ! -f "$STATE" ] && exit 0

        CURRENT=$(i3-msg -t get_tree | jq -r '.. | objects | select(.focused? == true) | .id' | head -1)
        if [ "$CURRENT" != "$BEFORE" ]; then
            FOCUSED_ID="$CURRENT"
            do_restore
            sleep 0.15
            i3-msg "[con_id=$FOCUSED_ID] focus" >/dev/null 2>&1
            exit 0
        fi
    done
) &
echo $! > "$HOOK"

exit 0
