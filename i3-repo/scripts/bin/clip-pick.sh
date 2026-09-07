#!/bin/bash
# clip-pick.sh — pick from clipboard history and paste
HIST="/tmp/clip-history"
[ -f "$HIST" ] || exit 0

theme=$(ls ~/rofi-themes-collection/themes/*.rasi 2>/dev/null | shuf -n1)
theme_arg=(); [ -n "$theme" ] && theme_arg=(-theme "$theme")

selected=$(cat "$HIST" | rofi -dmenu -p "clipboard" -i "${theme_arg[@]}" 2>/dev/null)
[ -z "$selected" ] && exit 0

echo -n "$selected" | xclip -selection clipboard
xdotool key --clearmodifiers ctrl+v
