#!/bin/bash
# Save configuration from stdin to the config file

CONFIG_DIR="$HOME/.config/plasma_engine_potd"
CONFIG_FILE="$CONFIG_DIR/nextcloudprovider.conf"

# Create directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Read from stdin and write to config file
cat > "$CONFIG_FILE"

echo "Configuration saved to: $CONFIG_FILE"
echo "File contents:"
cat "$CONFIG_FILE"
