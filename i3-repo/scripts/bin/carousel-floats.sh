#!/bin/bash
# carousel-floats.sh — linear (coverflow) or arc carousel
STATE=/tmp/carousel-mode
if [ "$1" = "toggle" ]; then
  cur=$(cat "$STATE" 2>/dev/null || echo "arc")
  [ "$cur" = "linear" ] && echo "arc" > "$STATE" || echo "linear" > "$STATE"
fi
mode=$(cat "$STATE" 2>/dev/null || echo "linear")
echo "$HOME/bin/carousel-floats.sh" > /tmp/float-active-layout
source ~/bin/float-layout-common.sh

CX=$(( FX + FW / 2 ))
CY=$(( FY + FH / 2 ))

clamp_place() {
  local id=$1 x=$2 y=$3 w=$4 h=$5
  [ "$x" -lt "$FX" ] && x=$FX
  (( x + w > FX + FW )) && x=$(( FX + FW - w ))
  [ "$y" -lt "$FY" ] && y=$FY
  (( y + h > FY + FH )) && y=$(( FY + FH - h ))
  i3-msg "[con_id=$id] resize set $w $h, move position $x $y"
}

if [ "$mode" = "linear" ]; then
  MAX_W=$(( FW * 55 / 100 )); MAX_H=$(( FH * 65 / 100 ))
  STEP_X=$(( FW / (n + 1) ))
  [ "$STEP_X" -lt 60 ] && STEP_X=60
  for i in "${!ids[@]}"; do
    id="${ids[$i]}"
    scale=$(( 100 - i * 15 )); [ "$scale" -lt 40 ] && scale=40
    w=$(( MAX_W * scale / 100 ))
    h=$(( MAX_H * scale / 100 ))
    x=$(( CX - MAX_W / 2 + i * STEP_X ))
    y=$(( CY - h / 2 ))
    clamp_place "$id" $x $y $w $h
  done
else
  RX=$(( FW * 38 / 100 )); RY=$(( FH * 32 / 100 ))
  MAX_W=$(( FW * 50 / 100 )); MAX_H=$(( FH * 55 / 100 ))
  for i in "${!ids[@]}"; do
    id="${ids[$i]}"
    [ "$n" -eq 1 ] && angle_deg=270 || {
      spread=140
      angle_deg=$(( 270 - spread / 2 + i * spread / (n - 1) ))
    }
    px=$(echo "scale=0; a=$angle_deg * 3.14159265 / 180; $CX + $RX * c(a)" | bc -l | xargs printf "%.0f")
    py=$(echo "scale=0; a=$angle_deg * 3.14159265 / 180; $CY + $RY * s(a)" | bc -l | xargs printf "%.0f")
    scale=$(( 100 - i * 12 )); [ "$scale" -lt 45 ] && scale=45
    w=$(( MAX_W * scale / 100 ))
    h=$(( MAX_H * scale / 100 ))
    clamp_place "$id" $(( px - w/2 )) $(( py - h/2 )) $w $h
  done
fi

[ -n "$focused" ] && i3-msg "[con_id=$focused] focus"
