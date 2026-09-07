#!/bin/bash
# goto-mark.sh <mark>
# Focus a marked window. If it's floating, go TO its workspace instead of
# pulling it to the current workspace.

MARK="$1"
[[ -z "$MARK" ]] && exit 1

# Get the window info for this mark from the i3 tree
INFO=$(i3-msg -t get_tree | jq -r --arg m "$MARK" '
    [.. | objects
       | select(.marks? and (.marks | map(. == $m) | any))
    ] | first
    | {
        floating: ((.type // "") | test("floating")),
        ws: (
          # walk up to find the workspace name
          null
        )
      }
' 2>/dev/null)

# Simpler approach: get the workspace name of the marked container
WS_NAME=$(i3-msg -t get_tree | jq -r --arg m "$MARK" '
    def find_ws($node):
        if $node.type == "workspace" then $node.name
        elif ($node.nodes? // [] | length) > 0 then
            ($node.nodes[] | find_ws(.)) // empty
        elif ($node.floating_nodes? // [] | length) > 0 then
            ($node.floating_nodes[] | find_ws(.)) // empty
        else empty
        end;

    def find_mark_ws($node):
        if ($node.marks? // [] | map(. == $m) | any) then
            # found it — but we need its workspace, climb up handled differently
            "FOUND"
        else
            (
                (($node.nodes? // []) + ($node.floating_nodes? // []))[]
                | find_mark_ws(.)
            ) // empty
        end;

    # Better: find the workspace that contains a node with this mark
    .. | objects
       | select(.type == "workspace")
       | select(
           [.. | objects | select(.marks? and (.marks | map(. == $m) | any))] | length > 0
         )
       | .name
' 2>/dev/null)

# Check if the window is floating
IS_FLOATING=$(i3-msg -t get_tree | jq -r --arg m "$MARK" '
    [.. | objects | select(.marks? and (.marks | map(. == $m) | any))] | first
    | .floating // "not_floating"
' 2>/dev/null)

CURRENT_WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name' 2>/dev/null)

# If floating and on a different workspace, switch there first
if [[ "$IS_FLOATING" == "user_on" || "$IS_FLOATING" == "auto_on" ]] && \
   [[ -n "$WS_NAME" ]] && [[ "$WS_NAME" != "$CURRENT_WS" ]]; then
    i3-msg "workspace \"$WS_NAME\""
fi

# Now focus the mark (it's now on the current workspace, or was tiled all along)
# Use regex with ^ and $ anchors for exact match
i3-msg "[con_mark=\"^$MARK$\"] focus"
