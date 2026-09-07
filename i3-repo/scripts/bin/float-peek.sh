#!/bin/bash
# float-peek.sh — temporarily surface ALL floating windows (all workspaces + scratchpad)
# so you can see what exists. Second press restores everything.

STATE=/tmp/float-peek-state
SAVE_DIR=/tmp/float-peek-saves

BAR=26
GAP=6

# --- RESTORE ---
if [ -f "$STATE" ]; then
  while IFS= read -r line; do
    id=$(echo "$line" | awk '{print $1}')
    ws=$(echo "$line" | awk '{print $2}')
    x=$(echo "$line"  | awk '{print $3}')
    y=$(echo "$line"  | awk '{print $4}')
    w=$(echo "$line"  | awk '{print $5}')
    h=$(echo "$line"  | awk '{print $6}')
    vis=$(echo "$line" | awk '{print $7}')

    if [ "$vis" = "scratch" ]; then
      i3-msg "[con_id=$id] move scratchpad" >/dev/null
    elif [ "$vis" = "other_ws" ]; then
      i3-msg "[con_id=$id] move to workspace $ws" >/dev/null
    else
      i3-msg "[con_id=$id] resize set $w $h, move position $x $y" >/dev/null
    fi
  done < "$STATE"
  rm -f "$STATE"
  exit 0
fi

# --- PEEK ---
TREE=$(i3-msg -t get_tree)

# Current workspace name
CUR_WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

# Output geometry
read -r OX OY OW OH < <(echo "$TREE" | jq -r '
  .. | objects
  | select(.type? == "output" and .name? != "__i3")
  | select(.. | objects | select(.focused? == true) | .id? != null)
  | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"
' | head -1)
[ -z "$OX" ] && OX=0 OY=0 OW=1920 OH=1080

ZX=$OX; ZY=$((OY + BAR))
ZW=$OW; ZH=$((OH - BAR * 2))

mkdir -p "$SAVE_DIR"
> "$STATE"

# Collect ALL floating windows: visible on any workspace + scratchpad
mapfile -t ALL < <(echo "$TREE" | jq -r '
  .. | objects | select(.window != null) |
  select(.floating? == "user_on" or .floating? == "auto_on") |
  "\(.id) \(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"
')

# Scratchpad windows
mapfile -t SCRATCH < <(echo "$TREE" | jq -r '
  .. | objects
  | select(.type? == "workspace" and .name? == "__i3_scratch")
  | .. | objects | select(.window != null)
  | "\(.id) \(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"
')

# Save state and bring everything to current workspace
declare -A seen
for entry in "${ALL[@]}"; do
  id=$(echo "$entry" | awk '{print $1}')
  x=$(echo "$entry"  | awk '{print $2}')
  y=$(echo "$entry"  | awk '{print $3}')
  w=$(echo "$entry"  | awk '{print $4}')
  h=$(echo "$entry"  | awk '{print $5}')
  seen[$id]=1

  # Which workspace is it on?
  ws=$(echo "$TREE" | jq -r --argjson id "$id" '
    .. | objects | select(.type? == "workspace") |
    select(.. | objects | select(.id? == $id) | .id? != null) |
    .name' | head -1)

  if [ "$ws" = "$CUR_WS" ]; then
    echo "$id $ws $x $y $w $h current" >> "$STATE"
  else
    echo "$id $ws $x $y $w $h other_ws" >> "$STATE"
    i3-msg "[con_id=$id] move to workspace $CUR_WS" >/dev/null
    sleep 0.05
  fi
done

for entry in "${SCRATCH[@]}"; do
  id=$(echo "$entry" | awk '{print $1}')
  [ "${seen[$id]}" = "1" ] && continue
  x=$(echo "$entry" | awk '{print $2}')
  y=$(echo "$entry" | awk '{print $3}')
  w=$(echo "$entry" | awk '{print $4}')
  h=$(echo "$entry" | awk '{print $5}')
  echo "$id __scratch__ $x $y $w $h scratch" >> "$STATE"
  i3-msg "[con_id=$id] scratchpad show" >/dev/null
  sleep 0.05
done

# Re-read all IDs now on current workspace
mapfile -t IDS < <(awk '{print $1}' "$STATE")
N=${#IDS[@]}
[ "$N" -eq 0 ] && rm -f "$STATE" && exit 0

# Grid layout across full screen
COLS=$(echo "sqrt($N)" | bc)
(( COLS < 1 )) && COLS=1
ROWS=$(( (N + COLS - 1) / COLS ))
(( COLS * ROWS < N )) && COLS=$((COLS + 1)) && ROWS=$(( (N + COLS - 1) / COLS ))

CW=$(( (ZW - GAP * (COLS + 1)) / COLS ))
CH=$(( (ZH - GAP * (ROWS + 1)) / ROWS ))
[ "$CW" -lt 80 ] && CW=80
[ "$CH" -lt 60 ] && CH=60

for i in "${!IDS[@]}"; do
  id="${IDS[$i]}"
  col=$(( i % COLS )); row=$(( i / COLS ))
  x=$(( ZX + GAP + col * (CW + GAP) ))
  y=$(( ZY + GAP + row * (CH + GAP) ))
  i3-msg "[con_id=$id] floating enable, resize set $CW $CH, move position $x $y" >/dev/null
done
