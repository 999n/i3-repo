#!/bin/bash
# i3-title-format.sh
# Watches all windows and strips app-name suffixes from titles
# Dependencies: xdotool, xprop
# Usage: exec_always --no-startup-id ~/.config/i3/i3-title-format.sh

STRIP_PATTERNS=(
    " [–-]+ Google Chrome$"
    " [–-]+ Mozilla Firefox$"
    " [–-]+ Chromium$"
    " - Visual Studio Code$"
    " [–-]+ Microsoft Edge$"
    " [–-]+ Brave$"
    " \| LinkedIn$"
    " \| Twitter$"
    " \| Facebook$"
    " on Instagram$"
    " • Instagram$"
    " - YouTube$"
    " - Reddit$"
)

clean_title() {
    local title="$1"
    for pattern in "${STRIP_PATTERNS[@]}"; do
        title=$(echo "$title" | sed -E "s/${pattern}//")
    done
    echo "${title:0:15}"
}

rename_window() {
    local xid="$1"
    local raw clean
    raw=$(xdotool getwindowname "$xid" 2>/dev/null) || return
    clean=$(clean_title "$raw")
    [[ "$clean" != "$raw" ]] && xdotool set_window --name "$clean" "$xid" 2>/dev/null
}

# Track which XIDs already have a watcher
declare -A watched

watch_window() {
    local xid="$1"
    [[ -n "${watched[$xid]}" ]] && return
    watched[$xid]=1

    rename_window "$xid"
    (
        xprop -id "$xid" -spy _NET_WM_NAME WM_NAME 2>/dev/null | while read -r; do
            rename_window "$xid"
        done
    ) &
}

# Watch existing windows
while read -r xid; do
    watch_window "$xid"
done < <(xdotool search --onlyvisible --name "" 2>/dev/null)

# Watch for new windows via root _NET_CLIENT_LIST changes
xprop -root -spy _NET_CLIENT_LIST 2>/dev/null | while read -r; do
    while read -r xid; do
        watch_window "$xid"
    done < <(xdotool search --onlyvisible --name "" 2>/dev/null)
done
