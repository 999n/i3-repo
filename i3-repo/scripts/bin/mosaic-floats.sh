#!/bin/bash
# mosaic-floats.sh (Mod4+t)
# mode 0: auto cols | mode 1: force 2 cols | mode 2: force 3 cols
STATE=/tmp/mosaic-mode
if [ "$1" = "next" ]; then
  cur=$(cat "$STATE" 2>/dev/null || echo "0")
  echo $(( (cur + 1) % 3 )) > "$STATE"
fi
mode=$(cat "$STATE" 2>/dev/null || echo "0")
echo "$HOME/bin/mosaic-floats.sh" > /tmp/float-active-layout
source ~/bin/float-layout-common.sh

case "$mode" in
  0)
    if   [ "$n" -le 1 ]; then cols=1
    elif [ "$n" -le 2 ]; then cols=2
    elif [ "$n" -le 4 ]; then cols=2
    elif [ "$n" -le 6 ]; then cols=3
    else cols=4; fi ;;
  1) cols=2 ;;
  2) cols=3 ;;
esac
[ "$cols" -gt "$n" ] && cols=$n
rows=$(( (n + cols - 1) / cols ))
base_cw=$(( (FW - P*(cols+1)) / cols ))
base_ch=$(( (FH - P*(rows+1)) / rows ))
[ "$base_cw" -lt 80 ] && base_cw=80
[ "$base_ch" -lt 60 ] && base_ch=60

for (( i=0; i<n; i++ )); do
  col=$(( i % cols )); row=$(( i / cols ))
  cw=$(( col == cols-1 ? FX + FW - P - (FX + P + col*(base_cw+P)) : base_cw ))
  ch=$(( row == rows-1 ? FY + FH - P - (FY + P + row*(base_ch+P)) : base_ch ))
  [ "$cw" -lt 80 ] && cw=80; [ "$ch" -lt 60 ] && ch=60
  place "${ids[$i]}" $(( FX + P + col*(base_cw+P) )) $(( FY + P + row*(base_ch+P) )) $cw $ch
done
[ -n "$focused" ] && i3-msg "[con_id=$focused] focus"
