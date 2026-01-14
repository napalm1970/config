#!/bin/bash
# Script to adjust Alacritty opacity
CONFIG="$HOME/.config/alacritty/alacritty.toml"
STEP="$1"

# Check if file exists
if [ ! -f "$CONFIG" ]; then
    exit 1
fi

# Use awk to calculate and replace
awk -v step="$STEP" '
/^opacity/ {
    val = $3 + step
    if (val > 1.0) val = 1.0
    if (val < 0.1) val = 0.1
    printf "opacity = %.2f\n", val
    next
}
{ print }
' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
