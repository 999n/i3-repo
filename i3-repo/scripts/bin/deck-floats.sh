#!/bin/bash
# deck-floats.sh (Mod4+y)
# mode 0: 65/35 | mode 1: 50/50 | mode 2: 75/25
STATE=/tmp/deck-mode
if [ "$1" = "next" ]; then
  cur=$(cat "$STATE" 2>/dev/null || echo "0")
  echo $(( (cur + 1) % 3 )) > "$STATE"
fi
mode=$(cat "$STATE" 2>/dev/null || echo "0")
echo "$HOME/bin/deck-floats.sh" > /tmp/float-active-layout
source ~/bin/float-layout-common.sh

case "$mode" in 0) pct=65 ;; 1) pct=50 ;; 2) pct=75 ;; esac

if [ "$n" -eq 1 ]; then
  place "${ids[0]}" $(( FX + P )) $(( FY + P )) $(( FW - P*2 )) $(( FH - P*2 ))
else
  main_w=$(( (FW - P*3) * pct / 100 ))
  side_w=$(( FW - P*3 - main_w ))
  [ "$side_w" -lt 80 ] && side_w=80
  others=$(( n - 1 ))
  base_ch=$(( (FH - P*(others+1)) / others ))
  [ "$base_ch" -lt 60 ] && base_ch=60

  place "${ids[0]}" $(( FX + P )) $(( FY + P )) $main_w $(( FH - P*2 ))
  sx=$(( FX + P + main_w + P )); sy=$(( FY + P ))
  for (( i=1; i<n; i++ )); do
    ch=$(( i == n-1 ? FY + FH - P - sy : base_ch ))
    [ "$ch" -lt 60 ] && ch=60
    place "${ids[$i]}" $sx $sy $side_w $ch
    sy=$(( sy + ch + P ))
  done
fi
[ -n "$focused" ] && i3-msg "[con_id=$focused] focus"
