#!/bin/bash
# still-floats.sh — grid layout where windows NEVER move on focus change
# Mod4+Ctrl+g       → apply / reapply
# Mod4+Ctrl+Shift+g → cycle slot order (rotate positions)
#
# Mechanism: writes /tmp/float-focus-lock while active.
# float-layout-watcher.py must skip re-running layout when that file exists.

LOCK=/tmp/float-focus-lock
STATE=/tmp/still-order

# Toggle off if already active and no args
if [ "$1" = "off" ] || ( [ -z "$1" ] && [ -f "$LOCK" ] && [ "$(cat $LOCK)" = "still" ] ); then
  rm -f "$LOCK" "$STATE"
  notify-send -u low -t 1500 "Still Mode OFF" "Floats resume normal layout"
  exit 0
fi

echo "still" > "$LOCK"

source ~/bin/float-layout-common.sh
# Provides: FX FY FW FH P all_ids focused n

[ "$n" -eq 0 ] && exit 0

# --- Stable order (not focus-based) ---
declare -A present
for id in "${all_ids[@]}"; do present[$id]=1; done

stable=()
if [ -f "$STATE" ]; then
  while IFS= read -r id; do
    [ -n "${present[$id]}" ] && stable+=("$id")
  done < "$STATE"
fi
for id in "${all_ids[@]}"; do
  found=0
  for s in "${stable[@]}"; do [ "$s" = "$id" ] && found=1 && break; done
  [ "$found" -eq 0 ] && stable+=("$id")
done

[ "$1" = "next" ] && stable=("${stable[@]:1}" "${stable[0]}")

printf '%s\n' "${stable[@]}" > "$STATE"
n=${#stable[@]}

# --- Layout ---
if [ "$1" = "fill" ]; then
  # Pack into the actual empty zone left by tiling (FX/FW from common.sh)
  # 1 window  → full zone
  # 2 windows → top / bottom halves
  # 3+        → two rows: ceil(n/2) on top, floor(n/2) on bottom
  top_n=$(( (n + 1) / 2 ))
  bot_n=$(( n / 2 ))

  place_row() {
    local start=$1 count=$2 ry=$3 rh=$4
    local rw=$(( (FW - P * (count + 1)) / count ))
    (( rw < 80 )) && rw=80
    for (( j=0; j<count; j++ )); do
      local rx=$(( FX + P + j * (rw + P) ))
      i3-msg "[con_id=${stable[$((start + j))]}] resize set $rw $rh, move position $rx $ry"
    done
  }

  if [ "$n" -eq 1 ]; then
    i3-msg "[con_id=${stable[0]}] resize set $(( FW - 2*P )) $(( FH - 2*P )), move position $(( FX + P )) $(( FY + P ))"
  elif [ "$n" -eq 2 ]; then
    rh=$(( (FH - 3*P) / 2 ))
    place_row 0 1 $(( FY + P ))        $rh
    place_row 1 1 $(( FY + 2*P + rh )) $rh
  else
    rh=$(( (FH - 3*P) / 2 ))
    place_row 0      $top_n $(( FY + P ))        $rh
    place_row $top_n $bot_n $(( FY + 2*P + rh )) $rh
  fi

  notify-send -u low -t 1500 "Still Fill" "$n windows packed into empty zone"
else
  # Even grid across the float zone
  cols=$(( n <= 2 ? n : n <= 4 ? 2 : 3 ))
  rows=$(( (n + cols - 1) / cols ))
  cw=$(( (FW - P * (cols + 1)) / cols ))
  ch=$(( (FH - P * (rows + 1)) / rows ))
  (( cw < 80 )) && cw=80
  (( ch < 80 )) && ch=80

  for (( i=0; i<n; i++ )); do
    col=$(( i % cols ))
    row=$(( i / cols ))
    x=$(( FX + P + col * (cw + P) ))
    y=$(( FY + P + row * (ch + P) ))
    i3-msg "[con_id=${stable[$i]}] resize set $cw $ch, move position $x $y"
  done

  notify-send -u low -t 1500 "Still Mode ON" "$n windows locked in grid"
fi
