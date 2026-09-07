#!/bin/bash
# spotlight-floats.sh (Mod4+o)
# mode 0: focused top-left 65x70%, others right+bottom
# mode 1: focused top-right, others left+bottom
# mode 2: focused center 60%, others bottom row

STATE=/tmp/spotlight-mode

if [ "$1" = "next" ]; then
  cur=$(cat "$STATE" 2>/dev/null || echo "0")
  echo $(( (cur + 1) % 3 )) > "$STATE"
fi

mode=$(cat "$STATE" 2>/dev/null || echo "0")
echo "$HOME/bin/spotlight-floats.sh" > /tmp/float-active-layout

source ~/bin/float-layout-common.sh

# Ensure P is defined and reasonable
: ${P:=10}          # default gap 10px if not set in common script
MIN_SIZE=80         # minimum width/height for any window

# Helper: ensure a value is at least MIN
min() { echo $(( $1 < MIN_SIZE ? MIN_SIZE : $1 )); }

# Helper: clamp value to be between low and high
clamp() {
  local val=$1 low=$2 high=$3
  if [ $val -lt $low ]; then echo $low
  elif [ $val -gt $high ]; then echo $high
  else echo $val
  fi
}

# If only one window, fill the work area
if [ "$n" -eq 1 ]; then
  place "${ids[0]}" $(( FX + P )) $(( FY + P )) \
        $(( FW - 2*P )) $(( FH - 2*P ))
  [ -n "$focused" ] && i3-msg "[con_id=$focused] focus"
  exit 0
fi

others=$(( n - 1 ))

case "$mode" in
0)
  # --- Focused (top-left) ---
  # Max available for focused: width = FW - 3P (left gap + gap to right + right gap)
  #                            height = FH - 3P (top gap + gap to bottom + bottom gap)
  max_fw=$(( FW - 3*P ))
  max_fh=$(( FH - 3*P ))
  mw=$(min $(( max_fw * 65 / 100 )))
  mh=$(min $(( max_fh * 70 / 100 )))
  # Ensure focused doesn't exceed available space
  mw=$(clamp $mw 80 $max_fw)
  mh=$(clamp $mh 80 $max_fh)
  place "${ids[0]}" $(( FX + P )) $(( FY + P )) $mw $mh

  # --- Right window (if exists) ---
  if [ "$others" -ge 1 ]; then
    rw=$(( FW - 3*P - mw ))   # remaining width after left padding, focused, gap, right padding
    rw=$(clamp $rw $MIN_SIZE $(( FW - 2*P )))
    # Height: from top gap to bottom gap
    rh=$(( FH - 2*P ))
    rh=$(clamp $rh $MIN_SIZE $(( FH - 2*P )))
    place "${ids[1]}" $(( FX + 2*P + mw )) $(( FY + P )) $rw $rh
  fi

  # --- Bottom row (remaining windows) ---
  bot_count=$(( others - 1 ))
  if [ "$bot_count" -gt 0 ]; then
    # Available width for bottom row: under focused window (from left padding to right edge of focused)
    avail_bottom_w=$(( mw - 2*P ))   # subtract left padding inside bottom area? Actually we want to fill under focused.
    # But originally they used the full mw minus gaps for multiple bottom windows.
    # Let's use the original logic but with safety.
    # The bottom row is placed under the focused window, spanning its width.
    # We'll compute widths for each bottom window, ensuring they fit.
    total_gaps=$(( (bot_count - 1) * P ))
    avail_width=$(( mw - total_gaps ))
    # Each window gets at least MIN_SIZE, so adjust if needed
    if [ $avail_width -lt $(( bot_count * MIN_SIZE )) ]; then
      # Not enough space; shrink focused window to make room? That would affect right window.
      # For simplicity, we'll just use the available width and let the last window take the remainder.
      # But we also need to keep heights within bounds.
      base_cw=$(( avail_width / bot_count ))
      base_cw=$(clamp $base_cw $MIN_SIZE $avail_width)
    else
      base_cw=$(( avail_width / bot_count ))
    fi
    bh=$(( FH - 3*P - mh ))   # height = remaining after top padding, focused, gap, bottom padding
    bh=$(clamp $bh $MIN_SIZE $(( FH - 2*P )))
    by=$(( FY + P + mh + P ))
    bx=$(( FX + P ))
    for (( i=2; i<n; i++ )); do
      j=$(( i - 2 ))
      if [ $j -eq $(( bot_count - 1 )) ]; then
        cw=$(( mw - P - (bx - (FX + P)) ))   # fill remaining space
      else
        cw=$base_cw
      fi
      cw=$(clamp $cw $MIN_SIZE $(( mw - (bx - (FX + P)) - P )))
      place "${ids[$i]}" $bx $by $cw $bh
      bx=$(( bx + cw + P ))
    done
  fi
  ;;

1)
  # Mode 1: focused top-right, left window, bottom row
  max_fw=$(( FW - 3*P ))
  max_fh=$(( FH - 3*P ))
  mw=$(min $(( max_fw * 65 / 100 )))
  mh=$(min $(( max_fh * 70 / 100 )))
  mw=$(clamp $mw 80 $max_fw)
  mh=$(clamp $mh 80 $max_fh)
  mx=$(( FX + FW - P - mw ))
  place "${ids[0]}" $mx $(( FY + P )) $mw $mh

  # Left window
  if [ "$others" -ge 1 ]; then
    lw=$(( FW - 3*P - mw ))
    lw=$(clamp $lw $MIN_SIZE $(( FW - 2*P )))
    lh=$(( FH - 2*P ))
    lh=$(clamp $lh $MIN_SIZE $(( FH - 2*P )))
    place "${ids[1]}" $(( FX + P )) $(( FY + P )) $lw $lh
  fi

  # Bottom row (under focused)
  bot_count=$(( others - 1 ))
  if [ "$bot_count" -gt 0 ]; then
    avail_bottom_w=$(( mw - 2*P ))
    total_gaps=$(( (bot_count - 1) * P ))
    avail_width=$(( mw - total_gaps ))
    base_cw=$(( avail_width / bot_count ))
    base_cw=$(clamp $base_cw $MIN_SIZE $avail_width)
    bh=$(( FH - 3*P - mh ))
    bh=$(clamp $bh $MIN_SIZE $(( FH - 2*P )))
    by=$(( FY + P + mh + P ))
    bx=$mx
    for (( i=2; i<n; i++ )); do
      j=$(( i - 2 ))
      if [ $j -eq $(( bot_count - 1 )) ]; then
        cw=$(( mw - P - (bx - mx) ))
      else
        cw=$base_cw
      fi
      cw=$(clamp $cw $MIN_SIZE $(( mw - (bx - mx) - P )))
      place "${ids[$i]}" $bx $by $cw $bh
      bx=$(( bx + cw + P ))
    done
  fi
  ;;

2)
  # Mode 2: centered spotlight, bottom row of all others
  max_fw=$(( FW - 2*P ))   # we don't need extra gaps for sides because it's centered
  max_fh=$(( FH - 2*P ))
  mw=$(min $(( max_fw * 60 / 100 )))
  mh=$(min $(( max_fh * 60 / 100 )))
  mw=$(clamp $mw $MIN_SIZE $max_fw)
  mh=$(clamp $mh $MIN_SIZE $max_fh)
  mx=$(( FX + (FW - mw) / 2 ))
  my=$(( FY + (FH - mh) / 2 ))
  place "${ids[0]}" $mx $my $mw $mh

  # Bottom row of all other windows
  bot_count=$others
  if [ "$bot_count" -gt 0 ]; then
    total_gaps=$(( (bot_count - 1) * P ))
    avail_width=$(( FW - 2*P - total_gaps ))
    base_cw=$(( avail_width / bot_count ))
    base_cw=$(clamp $base_cw $MIN_SIZE $avail_width)
    bh=$(( FH - 3*P - mh ))
    bh=$(clamp $bh $MIN_SIZE $(( FH - 2*P )))
    by=$(( my + mh + P ))
    # If bottom row is too low, force it to the bottom edge
    if [ $(( by + bh )) -gt $(( FY + FH - P )) ]; then
      by=$(( FY + FH - P - bh ))
    fi
    bx=$(( FX + P ))
    for (( i=1; i<n; i++ )); do
      j=$(( i - 1 ))
      if [ $j -eq $(( bot_count - 1 )) ]; then
        cw=$(( FW - 2*P - (bx - (FX + P)) ))
      else
        cw=$base_cw
      fi
      cw=$(clamp $cw $MIN_SIZE $(( FW - 2*P - (bx - (FX + P)) )))
      place "${ids[$i]}" $bx $by $cw $bh
      bx=$(( bx + cw + P ))
    done
  fi
  ;;
esac

# Restore focus to the original window
[ -n "$focused" ] && i3-msg "[con_id=$focused] focus"