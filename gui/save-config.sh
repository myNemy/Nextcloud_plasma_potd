#!/bin/bash
# Save configuration from stdin to the config file

CONFIG_DIR="$HOME/.config/plasma_engine_potd"
CONFIG_FILE="$CONFIG_DIR/nextcloudprovider.conf"

# Create directory if it doesn't exist
mkdir -p "$CONFIG_DIR" || exit 1

# Read from stdin and write to config file
cat > "$CONFIG_FILE" || exit 1

echo "Configuration saved to: $CONFIG_FILE"
