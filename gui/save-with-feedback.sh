#!/bin/bash
# Save configuration and write result to feedback file

CONFIG_DIR="$HOME/.config/plasma_engine_potd"
CONFIG_FILE="$CONFIG_DIR/nextcloudprovider.conf"
RESULT_FILE="/tmp/nextcloud_save_result.txt"

# Create directory if it doesn't exist
mkdir -p "$CONFIG_DIR" || {
    echo "ERROR: Could not create config directory" > "$RESULT_FILE"
    exit 1
}

# Read from stdin and write to config file
cat > "$CONFIG_FILE" || {
    echo "ERROR: Could not write config file" > "$RESULT_FILE"
    exit 1
}

# Success
echo "SUCCESS:$CONFIG_FILE" > "$RESULT_FILE"
exit 0

