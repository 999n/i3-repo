#!/bin/bash
# rofi-random.sh
rofi -show drun -theme "$(ls ~/rofi-themes-collection/themes/*.rasi | shuf -n1)" -show-icons
