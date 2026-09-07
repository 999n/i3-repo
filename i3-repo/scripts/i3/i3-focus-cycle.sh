#!/bin/bash
# Cycle through focus history (forward/back)
HISTORY_FILE="/tmp/i3-focus-history"
[[ -f "$HISTORY_FILE" ]] || exit 0

mapfile -t IDS < "$HISTORY_FILE"
[[ ${#IDS[@]} -eq 0 ]] && exit 0

FOCUSED=$(i3-msg -t get_tree | jq -r '.. | objects | select(.focused == true) | .id')

NEXT=1  # default: go to previous (index 1 = last focused before current)
if [[ "${1:-}" == "back" ]]; then
    for i in "${!IDS[@]}"; do
        [[ "${IDS[$i]}" == "$FOCUSED" ]] && NEXT=$(( i + 1 )) && break
    done
fi

NEXT=$(( NEXT % ${#IDS[@]} ))
i3-msg "[con_id=${IDS[$NEXT]}] focus"
