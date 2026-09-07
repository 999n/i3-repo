#!/bin/bash
# goto-hint.sh
# Sophisticated, icon-based mark navigator using Rofi with random themes

LETTER="$1"

# Extract marks AND window classes for icon matching using jq
MARKS_JSON=$(i3-msg -t get_tree | jq -r '
    [.. | objects | select(.marks? and (.marks | length > 0)) |
     {mark: .marks[], name: (.name // "(no title)"), class: (.window_properties.class // "unknown")}] |
    map(select(.mark != null and .mark != "stale_loud")) |
    map("\(.mark)\t\(.name)\t\(.class)") | .[]
')

if [[ -z "$MARKS_JSON" ]]; then
    dunstify -a "i3-goto-hint" -u low -t 15 -r 9902 " Marks" "No windows currently marked"
    exit 0
fi

# Parse JSON into a list for dunstify
CHOICES=$(while IFS=$'\t' read -r mark title class; do
    # Ensure variables exist
    [[ -z "$class" || "$class" == "unknown" ]] && class="window"
    
    # Filter by LETTER if provided
    if [[ -n "$LETTER" && "$mark" != "$LETTER"* ]]; then
        continue
    fi
    
    # Capitalize the first letter of the class for aesthetics
    class_cap="$(tr '[:lower:]' '[:upper:]' <<< "${class:0:1}")${class:1}"

    # Escape HTML/Pango entities for both title and class
    title="${title//&/&amp;}"
    title="${title//</&lt;}"
    title="${title//>/&gt;}"
    class_cap="${class_cap//&/&amp;}"
    class_cap="${class_cap//</&lt;}"
    class_cap="${class_cap//>/&gt;}"
    
    # Combine them: App Name first, then Page Title
    full_text="${class_cap} ‒ ${title}"
    
    # Clean up title width
    SHORT="${full_text:0:55}"
    [[ "${#full_text}" -gt 55 ]] && SHORT="${SHORT}…"
    
    # Format the mark in brackets and pad outside for better appearance
    bracketed="[${mark}]"
    padded="$bracketed"
    while [[ ${#padded} -lt 6 ]]; do padded="$padded "; done
    
    # Replace spaces with non-breaking spaces to avoid HTML/Pango collapsing them
    padded="${padded// /&#160;}"
    
    # Elegant Pango markup: Bold styled bracketed mark, and clean window name
    echo "<b><span font_family='choco cooky' size='large' color='#a6accd'>${padded}</span></b>&#160;&#160;<span size='large'>${SHORT}</span>"
done <<< "$MARKS_JSON")

if [[ -z "$CHOICES" ]]; then
    if [[ -n "$LETTER" ]]; then
        dunstify -a "i3-goto-hint" -u low -t 0 -r 9902 " Marks" "No windows matched for '$LETTER'"
    else
        dunstify -a "i3-goto-hint" -u low -t 0 -r 9902 " Marks" "No windows currently marked"
    fi
    exit 0
fi

# Display the marks as a notification, letting i3 modes handle keyboard input
dunstify -a "i3-goto-hint" -u low -t 0 -r 9902 " Marks" "$CHOICES"
