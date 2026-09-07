#!/bin/bash
# float-graveyard.sh — relaunch recently closed floating windows
# Called with: --record class title (from float-layout-watcher)
#              --pick   (rofi picker to relaunch)

GRAVE=/tmp/float-graveyard

if [ "$1" = "--record" ]; then
  class="$2"
  title="$3"
  [ -z "$class" ] && exit 0
  # Prepend, deduplicate by class, keep last 20
  tmp=$(mktemp)
  echo "$class|$title" > "$tmp"
  grep -v "^$class|" "$GRAVE" 2>/dev/null | head -19 >> "$tmp"
  mv "$tmp" "$GRAVE"
  exit 0
fi

# --pick mode
[ ! -f "$GRAVE" ] && dunstify -u low "float-graveyard: nothing closed yet" && exit 0

theme=$(ls ~/rofi-themes-collection/themes/*.rasi 2>/dev/null | shuf -n1)
theme_arg=(); [ -n "$theme" ] && theme_arg=(-theme "$theme")

selected=$(awk -F'|' '{print NR". "$1"  —  "$2}' "$GRAVE" | \
  rofi -dmenu -p "relaunch" -i "${theme_arg[@]}" 2>/dev/null)
[ -z "$selected" ] && exit 0

class=$(echo "$selected" | sed 's/^[0-9]*\. //' | awk -F'  —  ' '{print $1}' | xargs)

# Map class → launch command
case "${class,,}" in
  mousepad)        cmd="mousepad" ;;
  thunar)          cmd="thunar" ;;
  pavucontrol)     cmd="pavucontrol" ;;
  nitrogen)        cmd="nitrogen" ;;
  google-chrome*|chrome) cmd="google-chrome-stable" ;;
  slack)           cmd="slack --disable-gpu --no-sandbox --ozone-platform=x11" ;;
  *)               cmd="$class" ;;
esac

i3-msg "exec --no-startup-id $cmd"
