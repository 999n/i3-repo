#!/bin/bash
# ws-note.sh — open a note tied to the current workspace
WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name')
mousepad "~/notes/ws${WS}.txt"
