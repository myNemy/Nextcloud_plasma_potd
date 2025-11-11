#!/bin/bash
# Execute save command and write result
# This script is called from QML to execute the save

CONFIG_TEXT="$1"
SCRIPT_DIR="$2"

if [ -z "$CONFIG_TEXT" ] || [ -z "$SCRIPT_DIR" ]; then
    echo "ERROR: Missing parameters" > /tmp/nextcloud_save_result.txt
    exit 1
fi

# Execute save script
echo "$CONFIG_TEXT" | bash "$SCRIPT_DIR/save-with-feedback.sh"

