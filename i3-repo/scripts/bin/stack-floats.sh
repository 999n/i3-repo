#!/bin/bash
# stack-floats.sh (Mod4+r)
# mode 0: focused 55% top, rest below | mode 1: all equal | mode 2: focused 35% top
STATE=/tmp/stack-mode
if [ "$1" = "next" ]; then
  cur=$(cat "$STATE" 2>/dev/null || echo "0")
  echo $(( (cur + 1) % 3 )) > "$STATE"
fi
mode=$(cat "$STATE" 2>/dev/null || echo "0")
echo "$HOME/bin/stack-floats.sh" > /tmp/float-active-layout
source ~/bin/float-layout-common.sh

W=$(( FW - P*2 ))
case "$mode" in
  0) pct=55 ;; 1) pct=$(( 100 / n )) ;; 2) pct=35 ;;
esac

if [ "$n" -eq 1 ]; then
  place "${ids[0]}" $(( FX + P )) $(( FY + P )) $W $(( FH - P*2 ))
else
  foc_h=$(( (FH - P*(n+1)) * pct / 100 ))
  [ "$foc_h" -lt 80 ] && foc_h=80
  others=$(( n - 1 ))
  cy=$(( FY + P + foc_h + P ))
  rem_h=$(( FY + FH - P - cy ))
  base_ch=$(( (rem_h - P*(others-1)) / others ))
  [ "$base_ch" -lt 60 ] && base_ch=60

  place "${ids[0]}" $(( FX + P )) $(( FY + P )) $W $foc_h
  for (( i=1; i<n; i++ )); do
    ch=$(( i == n-1 ? FY + FH - P - cy : base_ch ))
    [ "$ch" -lt 60 ] && ch=60
    place "${ids[$i]}" $(( FX + P )) $cy $W $ch
    cy=$(( cy + ch + P ))
  done
fi
[ -n "$focused" ] && i3-msg "[con_id=$focused] focus"
