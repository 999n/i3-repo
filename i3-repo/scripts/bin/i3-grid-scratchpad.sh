#!/usr/bin/env bash

# Screen/layout constants
SCREEN_W=1920
SCREEN_H=1080
BAR_H=23
GAP=6

USABLE_W=$((SCREEN_W))
USABLE_H=$((SCREEN_H - BAR_H))

# Move all scratchpad windows to workspace 1 (must show first to detach from scratchpad)
mapfile -t SCRATCH_IDS < <(i3-msg -t get_tree | python3 -c "
import json, sys
tree = json.load(sys.stdin)
def find_scratch(node):
    if node.get('name') == '__i3_scratch':
        for n in node.get('floating_nodes', []):
            print(n['id'])
        return
    for c in node.get('nodes', []) + node.get('floating_nodes', []):
        find_scratch(c)
find_scratch(tree)
")

for id in "${SCRATCH_IDS[@]}"; do
    # scratchpad show brings it to current workspace, then move it to ws1
    i3-msg "[con_id=$id] scratchpad show; [con_id=$id] move to workspace 1" >/dev/null
done

# Give i3 a moment to process moves
sleep 0.2

# Collect all floating window con_ids on workspace 1
mapfile -t IDS < <(i3-msg -t get_tree | python3 -c "
import json, sys
tree = json.load(sys.stdin)
def find_ws1_floating(node):
    if node.get('type') == 'workspace' and node.get('name') == '1':
        for n in node.get('floating_nodes', []):
            print(n['nodes'][0]['id'] if n.get('nodes') else n['id'])
        return
    for c in node.get('nodes', []) + node.get('floating_nodes', []):
        find_ws1_floating(c)
find_ws1_floating(tree)
")

N=${#IDS[@]}
[[ $N -eq 0 ]] && echo "No floating windows on workspace 1." && exit 0

# Calculate grid dimensions
COLS=$(( (N + 1) / 2 ))
[[ $N -le 2 ]] && COLS=$N
ROWS=$(( (N + COLS - 1) / COLS ))

WIN_W=$(( (USABLE_W - GAP * (COLS + 1)) / COLS ))
WIN_H=$(( (USABLE_H - GAP * (ROWS + 1)) / ROWS ))

# Suppress float-layout-watcher re-layout triggers while we work
touch /tmp/float-focus-lock
trap 'rm -f /tmp/float-focus-lock' EXIT

apply_grid() {
    local i=0
    for id in "${IDS[@]}"; do
        col=$(( i % COLS ))
        row=$(( i / COLS ))
        x=$(( GAP + col * (WIN_W + GAP) ))
        y=$(( BAR_H + GAP + row * (WIN_H + GAP) ))
        i3-msg "[con_id=$id] resize set $WIN_W $WIN_H; [con_id=$id] move absolute position $x $y" >/dev/null
        (( i++ ))
    done
}

# Apply immediately, then again after 0.5s and 1s to override any app-driven resize
apply_grid
sleep 0.5 && apply_grid
sleep 0.5 && apply_grid

echo "Arranged $N window(s) in ${COLS}x${ROWS} grid."
# Clear active layout so watcher doesn't re-apply it on next focus
rm -f /tmp/float-active-layout
