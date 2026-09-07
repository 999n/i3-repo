#!/bin/bash
# rofi-random-window.sh
rofi -show window -theme "$(ls ~/rofi-themes-collection/themes/*.rasi | shuf -n1)" -show-icons
