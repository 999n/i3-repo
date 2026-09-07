#!/bin/bash
# i3floatarrage.sh — Monocle float layout
# Focused window = large primary. Up to 2 others = mini strip (bottom-right).
# Clicking a strip window promotes it to primary on next run (via watcher).
# Extra windows go to scratchpad.
echo "$HOME/bin/i3floatarrage.sh" > /tmp/float-active-layout
source ~/bin/float-layout-common.sh
MIN=80
clamp() { local v=$1 lo=$2 hi=$3; (( v < lo )) && v=$lo; (( v > hi )) && v=$hi; echo $v; }

# Get actual monitor geometry to prevent off-screen placement
MONITOR_INFO=$(i3-msg -t get_outputs | jq '.[] | select(.active) | .rect')
MON_X=$(echo "$MONITOR_INFO" | jq '.x')
MON_Y=$(echo "$MONITOR_INFO" | jq '.y')
MON_W=$(echo "$MONITOR_INFO" | jq '.width')
MON_H=$(echo "$MONITOR_INFO" | jq '.height')

# ── Single window ─────────────────────────────────────────────────────────────
if [ "$n" -eq 1 ]; then
  place "${ids[0]}" $(( FX + P )) $(( FY + P )) $(( FW - 2*P )) $(( FH - 2*P ))
  i3-msg "[con_id=${ids[0]}] focus"
  exit 0
fi

# ── Strip config ──────────────────────────────────────────────────────────────
STRIP_MAX=2
STRIP_H=130
STRIP_W_EACH=160

# ── Primary: full zone ────────────────────────────────────────────────────────
place "${ids[0]}" $(( FX + P )) $(( FY + P )) $(( FW - 2*P )) $(( FH - 2*P ))

# ── Strip windows: placed on top of primary, bottom-right ────────────────────
# But clamped to stay within monitor bounds
strip_count=$(( n - 1 < STRIP_MAX ? n - 1 : STRIP_MAX ))
for (( i=1; i<=strip_count; i++ )); do
  slot=$(( strip_count - i ))
  sx=$(( FX + FW - P - STRIP_W_EACH - slot * (STRIP_W_EACH + P) ))
  sy=$(( FY + FH - P - STRIP_H ))
  
  # Clamp to monitor bounds
  sx=$(clamp $sx $MON_X $(( MON_X + MON_W - STRIP_W_EACH )))
  sy=$(clamp $sy $MON_Y $(( MON_Y + MON_H - STRIP_H )))
  
  place "${ids[$i]}" $sx $sy $STRIP_W_EACH $STRIP_H
done

# ── Scratchpad overflow ───────────────────────────────────────────────────────
for (( i=strip_count+1; i<n; i++ )); do
  i3-msg "[con_id=${ids[$i]}] move scratchpad"
done

if (( n - 1 > STRIP_MAX )); then
  notify-send -u low "monocle-float" "$(( n - 1 - STRIP_MAX )) window(s) in scratchpad (\$mod+minus)"
fi

# ── Raise strip windows above primary, then restore focus to primary ──────────
# Strip windows must be raised so they're clickable (not hidden behind primary).
for (( i=strip_count; i>=1; i-- )); do
  i3-msg "[con_id=${ids[$i]}] focus"
done

# Return focus to primary — clicking a strip window will re-run layout via watcher,
# promoting that window to primary naturally (it becomes focused → ids[0]).
i3-msg "[con_id=${ids[0]}] focus"
