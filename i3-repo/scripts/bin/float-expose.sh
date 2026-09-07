#!/bin/bash
# float-expose.sh — arrange visible floats + scratchpad windows into grid / restore

STATE_FILE="/tmp/i3-expose-state"
SAVE_DIR="/tmp/i3-expose-saves"
SCRATCH_FILE="/tmp/i3-expose-scratched"
BAR_HEIGHT=26
GAP=8

TREE=$(i3-msg -t get_tree)

read -r OUT_X OUT_Y OUT_W OUT_H < <(echo "$TREE" | jq -r '
  .. | objects
  | select(.type? == "output" and .name? != "__i3")
  | select(.. | objects | select(.focused? == true) | .id? != null)
  | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"
' | head -1)
[[ -z "$OUT_X" ]] && OUT_X=0 OUT_Y=0 OUT_W=1920 OUT_H=1080

ZONE_X=$((OUT_X + 960))
ZONE_W=$((OUT_W - 960 - 5))
ZONE_H=$((OUT_H - BAR_HEIGHT - 5))
ZONE_TOP=$((OUT_Y + BAR_HEIGHT))

restore_window() {
  local id=$1 save="$SAVE_DIR/$id"
  [[ -f "$save" ]] || return
  read -r x y w h < "$save"
  i3-msg "[con_id=$id] resize set $w $h, move position $x $y"
}

if [[ "${1:-}" == "restore-focused" ]]; then
  FOCUSED=$(echo "$TREE" | jq -r '.. | objects | select(.focused == true) | .id')
  if grep -q "^$FOCUSED$" "$SCRATCH_FILE" 2>/dev/null; then
    i3-msg "[con_id=$FOCUSED] move scratchpad"
    sed -i "/^$FOCUSED$/d" "$SCRATCH_FILE"
  else
    restore_window "$FOCUSED"
  fi
  rm -f "$SAVE_DIR/$FOCUSED"
  [[ $(ls "$SAVE_DIR" 2>/dev/null | wc -l) -eq 0 ]] && rm -f "$STATE_FILE" "$SCRATCH_FILE" && rmdir "$SAVE_DIR" 2>/dev/null
  exit 0
fi

if [[ -f "$STATE_FILE" ]]; then
  mapfile -t ALL_IDS < <(ls "$SAVE_DIR" 2>/dev/null)
  for id in "${ALL_IDS[@]}"; do
    if grep -q "^$id$" "$SCRATCH_FILE" 2>/dev/null; then
      i3-msg "[con_id=$id] move scratchpad"
    else
      restore_window "$id"
    fi
  done
  rm -f "$STATE_FILE" "$SCRATCH_FILE" "$SAVE_DIR"/*
  rmdir "$SAVE_DIR" 2>/dev/null
  exit 0
fi

mkdir -p "$SAVE_DIR"
touch "$STATE_FILE"
> "$SCRATCH_FILE"

mapfile -t VIS_IDS < <(echo "$TREE" | jq -r --argjson ox "$OUT_X" --argjson ow "$OUT_W" '
  .. | objects
  | select(.type? == "workspace" and .name? != "__i3_scratch" and .output? != "__i3")
  | .floating_nodes[]?
  | .nodes[]?
  | select(.floating? == "user_on")
  | select(.rect.x >= $ox and .rect.x < ($ox + $ow))
  | .id
')

mapfile -t SCRATCH_IDS < <(echo "$TREE" | jq -r '
  .. | objects
  | select(.type? == "workspace" and .name? == "__i3_scratch")
  | .. | objects
  | select(.marks? and (.marks | map(test("^[gs][^_]+_[0-9]+$")) | any))
  | .id
')

for id in "${VIS_IDS[@]}"; do
  read -r x y w h < <(echo "$TREE" | jq -r --argjson id "$id" '
    .. | objects | select(.id == $id) | "\(.rect.x) \(.rect.y) \(.rect.width) \(.rect.height)"')
  echo "$x $y $w $h" > "$SAVE_DIR/$id"
done

for id in "${SCRATCH_IDS[@]}"; do
  i3-msg "[con_id=$id] scratchpad show"
  sleep 0.05
  echo "$id" >> "$SCRATCH_FILE"
  echo "0 0 0 0" > "$SAVE_DIR/$id"
done

TREE=$(i3-msg -t get_tree)
ALL_IDS=("${VIS_IDS[@]}" "${SCRATCH_IDS[@]}")
COUNT=${#ALL_IDS[@]}
[[ $COUNT -eq 0 ]] && rm -f "$STATE_FILE" "$SCRATCH_FILE" && rmdir "$SAVE_DIR" 2>/dev/null && exit 0

COLS=$(echo "sqrt($COUNT)" | bc)
(( COLS < 1 )) && COLS=1
ROWS=$(( (COUNT + COLS - 1) / COLS ))
(( COLS * ROWS < COUNT )) && COLS=$((COLS + 1)) && ROWS=$(( (COUNT + COLS - 1) / COLS ))

CELL_W=$(( (ZONE_W - GAP * (COLS + 1)) / COLS ))
CELL_H=$(( (ZONE_H - GAP * (ROWS + 1)) / ROWS ))

for i in "${!ALL_IDS[@]}"; do
  id="${ALL_IDS[$i]}"
  col=$(( i % COLS )); row=$(( i / COLS ))
  x=$(( ZONE_X + GAP + col * (CELL_W + GAP) ))
  y=$(( ZONE_TOP + GAP + row * (CELL_H + GAP) ))
  i3-msg "[con_id=$id] resize set $CELL_W $CELL_H, move position $x $y"
done
