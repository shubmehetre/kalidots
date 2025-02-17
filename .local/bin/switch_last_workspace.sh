#!/bin/bash

# File to store the last workspace
LAST_WS_FILE="/tmp/last_workspace"

# Get current workspace
CURRENT_WS=$(wmctrl -d | awk '/\*/ {print $1}')

# If file exists, read the last workspace
if [ -f "$LAST_WS_FILE" ]; then
    LAST_WS=$(cat "$LAST_WS_FILE")
else
    LAST_WS=$CURRENT_WS
fi

# Save current workspace as last before switching
echo "$CURRENT_WS" > "$LAST_WS_FILE"

# Switch to last used workspace
wmctrl -s "$LAST_WS"
