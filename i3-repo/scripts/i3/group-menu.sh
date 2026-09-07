#!/bin/bash
# Group manager - single entry point for all group operations

GROUPS_FILE="/tmp/i3_groups.json"
ACTIVE_FILE="/tmp/i3_active_group"
HISTORY_FILE="/tmp/i3_group_history"

[[ ! -s "$GROUPS_FILE" ]] && echo '{}' > "$GROUPS_FILE"

# Clean up dead windows (windows that were closed)
ACTIVE_MARKS=$(i3-msg -t get_marks 2>/dev/null || echo "[]")
jq --argjson am "$ACTIVE_MARKS" 'map_values(map(select(.mark as $m | $am | index($m))))' "$GROUPS_FILE" > "${GROUPS_FILE}.tmp" && mv "${GROUPS_FILE}.tmp" "$GROUPS_FILE"

# Show active group in prompt
ACTIVE=$(cat "$ACTIVE_FILE" 2>/dev/null)
PROMPT="Groups"
[[ -n "$ACTIVE" ]] && PROMPT="Groups [Active: $ACTIVE]"

CHOICE=$(printf "Create group\nActivate group\nEdit group\nDelete group\nShow group info\nNext window\nPrev window" \
    | rofi -dmenu -p "$PROMPT:" -lines 7)
[[ -z "$CHOICE" ]] && exit 0

case "$CHOICE" in

  "Create group"|"Edit group")
    # Cache window tree query (used by both Create and Edit)
    ALL=$(i3-msg -t get_tree | jq '[recurse(.nodes[]?, .floating_nodes[]?) | select(type == "object") | select(.marks != null and (.marks | length) > 0) | select(any(.marks[]; . != "stale_loud")) | {id: .id, name: .name, mark: .marks[0]}]'  )
    COUNT=$(echo "$ALL" | jq 'length')
    [[ $COUNT -eq 0 ]] && { dunstify -u critical "No marked windows"; exit 1; }
    
    if [[ "$CHOICE" == "Create group" ]]; then
        # Let user pick which windows to include
        LIST=$(echo "$ALL" | jq -r '.[] | "\(.mark)  \(.name)"')
        SELECTED=$(echo "$LIST" | rofi -dmenu -p "Pick windows (multi-select):" -multi-select)
        [[ -z "$SELECTED" ]] && exit 0

        # Build windows array from selected marks
        MARKS=$(echo "$SELECTED" | awk '{print $1}' | paste -sd '|')
        WINDOWS=$(echo "$ALL" | jq --arg m "$MARKS" '[.[] | select(.mark | test($m)) | {mark: .mark, name: .name}]')
        WCOUNT=$(echo "$WINDOWS" | jq 'length')
        [[ $WCOUNT -eq 0 ]] && { dunstify -u critical "No windows matched"; exit 1; }

        # Ask group name
        NAME=$(echo "" | rofi -dmenu -p "Group name:" -lines 0)
        NAME=$(echo "$NAME" | xargs)
        [[ -z "$NAME" ]] && exit 0

        # Save and activate
        jq --arg n "$NAME" --argjson w "$WINDOWS" '.[$n] = $w' "$GROUPS_FILE" > "$GROUPS_FILE.tmp" && mv "$GROUPS_FILE.tmp" "$GROUPS_FILE"
        echo "$NAME" > "$ACTIVE_FILE"
        echo "$NAME" >> "$HISTORY_FILE"
        dunstify -u low "✅ Group '$NAME' created ($WCOUNT windows) — ACTIVE"
        
    else  # Edit group
        NAMES=$(jq -r 'keys[]' "$GROUPS_FILE")
        [[ -z "$NAMES" ]] && { dunstify -u critical "No groups saved"; exit 1; }

        NAME=$(echo "$NAMES" | rofi -dmenu -p "Edit group:")
        [[ -z "$NAME" ]] && exit 0

        # Merge existing group windows + currently marked windows, deduplicate by mark
        EXISTING=$(jq -c --arg n "$NAME" '.[$n] // []' "$GROUPS_FILE")
        MERGED=$(jq -n --argjson a "$EXISTING" --argjson b "$ALL" '$a + $b | unique_by(.mark)')

        # Build the display list (existing windows first, then new ones)
        LIST=$(echo "$MERGED" | jq -r '.[] | "\(.mark)  \(.name)"')

        # Build -select string: comma-separated indices of already-saved windows
        EXISTING_MARKS=$(jq -r --arg n "$NAME" '.[$n] // [] | .[].mark' "$GROUPS_FILE")
        SELECT_INDICES=$(echo "$MERGED" | jq -r --argjson ex "$EXISTING" \
            '[to_entries[] | select(.value.mark as $m | $ex | map(.mark) | index($m) != null) | .key] | join(",")')

        SELECTED=$(echo "$LIST" | rofi -dmenu -p "Add/remove windows for '$NAME':" -multi-select \
            ${SELECT_INDICES:+-select "$SELECT_INDICES"})
        [[ -z "$SELECTED" ]] && exit 0

        MARKS=$(echo "$SELECTED" | awk '{print $1}' | paste -sd '|')
        WINDOWS=$(echo "$MERGED" | jq --arg m "$MARKS" '[.[] | select(.mark | test($m)) | {mark: .mark, name: .name}]')
        WCOUNT=$(echo "$WINDOWS" | jq 'length')

        jq --arg n "$NAME" --argjson w "$WINDOWS" '.[$n] = $w' "$GROUPS_FILE" > "$GROUPS_FILE.tmp" && mv "$GROUPS_FILE.tmp" "$GROUPS_FILE"
        dunstify -u low "✅ Group '$NAME' updated ($WCOUNT windows)"
    fi
    ;;

  "Activate group")
    NAMES=$(jq -r 'keys[]' "$GROUPS_FILE")
    [[ -z "$NAMES" ]] && { dunstify -u critical "No groups saved"; exit 1; }

    ACTIVE=$(cat "$ACTIVE_FILE" 2>/dev/null)
    
    # Sort by recently used (read from history, then add rest)
    if [[ -f "$HISTORY_FILE" ]]; then
        RECENT=$(tac "$HISTORY_FILE" | awk '!seen[$0]++' | head -5)
        REST=$(echo "$NAMES" | grep -vFf <(echo "$RECENT") 2>/dev/null)
        SORTED=$(echo -e "$RECENT\n$REST" | grep -v '^$')
    else
        SORTED="$NAMES"
    fi
    
    # Mark active group with indicator and format quick slots
    MENU=$(echo "$SORTED" | while read -r n; do
      PREFIX="  "
      [[ "$n" == "$ACTIVE" ]] && PREFIX="▶ "
      
      # Format quick slots nicely
      if [[ "$n" =~ ^@quick([0-9]+)$ ]]; then
        SLOT="${BASH_REMATCH[1]}"
        COUNT=$(jq -r --arg g "$n" '.[$g] | length' "$GROUPS_FILE")
        echo "${PREFIX}[Q$SLOT] Quick slot $SLOT ($COUNT)"
      else
        echo "${PREFIX}$n"
      fi
    done)

    PICKED=$(echo "$MENU" | rofi -dmenu -p "Activate group:")
    [[ -z "$PICKED" ]] && exit 0
    
    # Extract actual name
    if [[ "$PICKED" =~ \[Q([0-9]+)\] ]]; then
        NAME="@quick${BASH_REMATCH[1]}"
    else
        NAME=$(echo "$PICKED" | sed 's/^[▶ ]*//')
    fi
    
    echo "$NAME" > "$ACTIVE_FILE"
    echo "$NAME" >> "$HISTORY_FILE"
    WCOUNT=$(jq -r --arg n "$NAME" '.[$n] | length' "$GROUPS_FILE")
    dunstify -u low "▶ Active group: '$NAME' ($WCOUNT windows)"
    ;;

  "Delete group")
    NAMES=$(jq -r 'keys[]' "$GROUPS_FILE")
    [[ -z "$NAMES" ]] && { dunstify -u critical "No groups saved"; exit 1; }

    NAME=$(echo "$NAMES" | rofi -dmenu -p "Delete group:")
    [[ -z "$NAME" ]] && exit 0

    jq --arg n "$NAME" 'del(.[$n])' "$GROUPS_FILE" > "$GROUPS_FILE.tmp" && mv "$GROUPS_FILE.tmp" "$GROUPS_FILE"

    # Clear active if deleted group was active
    ACTIVE=$(cat "$ACTIVE_FILE" 2>/dev/null)
    [[ "$ACTIVE" == "$NAME" ]] && rm -f "$ACTIVE_FILE"

    dunstify -u low "🗑 Group '$NAME' deleted"
    ;;

  "Show group info")
    NAMES=$(jq -r 'keys[]' "$GROUPS_FILE")
    [[ -z "$NAMES" ]] && { dunstify -u critical "No groups saved"; exit 1; }

    NAME=$(echo "$NAMES" | rofi -dmenu -p "Show info for group:")
    [[ -z "$NAME" ]] && exit 0

    # Get windows in this group
    WINDOWS=$(jq -r --arg n "$NAME" '.[$n][] | "\(.mark)  \(.name)"' "$GROUPS_FILE")
    COUNT=$(jq -r --arg n "$NAME" '.[$n] | length' "$GROUPS_FILE")
    
    # Check which windows still exist
    EXISTING_MARKS=$(i3-msg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(type == "object") | select(.marks != null) | .marks[]' | sort -u)
    
    INFO=$(echo "$WINDOWS" | while IFS= read -r line; do
        MARK=$(echo "$line" | awk '{print $1}')
        if echo "$EXISTING_MARKS" | grep -qx "$MARK"; then
            echo "✓ $line"
        else
            echo "✗ $line (window closed)"
        fi
    done)
    
    # Show in rofi as info display
    echo "$INFO" | rofi -dmenu -p "Group '$NAME' ($COUNT windows):" -mesg "✓ = exists, ✗ = closed" -no-custom
    ;;

  "Next window")
    ~/.config/i3/group-next.sh
    ;;

  "Prev window")
    ~/.config/i3/group-prev.sh
    ;;

esac
