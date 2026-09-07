#!/bin/bash
# ribbon-floats.sh (Mod4+p)
# mode 0: single row | mode 1: two rows | mode 2: auto rows (best aspect ratio)
STATE=/tmp/ribbon-mode
if [ "$1" = "next" ]; then
  cur=$(cat "$STATE" 2>/dev/null || echo "0")
  echo $(( (cur + 1) % 3 )) > "$STATE"
fi
mode=$(cat "$STATE" 2>/dev/null || echo "0")
echo "$HOME/bin/ribbon-floats.sh" > /tmp/float-active-layout
source ~/bin/float-layout-common.sh

case "$mode" in
  0) rows=1 ;;
  1) rows=2 ;;
  2)
    best_rows=1; best_diff=99999
    for r in 1 2 3 4; do
      cols_r=$(( (n + r - 1) / r ))
      cw=$(( (FW - P*(cols_r+1)) / cols_r ))
      ch=$(( (FH - P*(r+1)) / r ))
      [ "$cw" -lt 1 ] && cw=1; [ "$ch" -lt 1 ] && ch=1
      ratio=$(( cw * 9 / ch ))
      diff=$(( ratio > 16 ? ratio - 16 : 16 - ratio ))
      if [ "$diff" -lt "$best_diff" ]; then best_diff=$diff; best_rows=$r; fi
    done
    rows=$best_rows ;;
esac

[ "$rows" -gt "$n" ] && rows=$n
cols=$(( (n + rows - 1) / rows ))
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
