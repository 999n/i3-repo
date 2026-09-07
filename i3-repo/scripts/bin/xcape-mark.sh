#!/bin/bash
# xcape-mark.sh — tap Mod4 alone to enter mark mode
killall xcape 2>/dev/null
xcape -e 'Super_L=F13'
