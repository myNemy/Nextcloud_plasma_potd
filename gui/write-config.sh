#!/bin/bash
# Helper to write config from JSON

CONFIG_DIR="$HOME/.config/plasma_engine_potd"
CONFIG_FILE="$CONFIG_DIR/nextcloudprovider.conf"

mkdir -p "$CONFIG_DIR"

# Read JSON from stdin and write INI
cat > "$CONFIG_FILE" << 'EOF'
[Nextcloud]
EOF

# Parse JSON (simple approach - expects specific format)
while IFS= read -r line; do
    if [[ $line =~ \"Url\":\"([^\"]+)\" ]]; then
        echo "Url=${BASH_REMATCH[1]}" >> "$CONFIG_FILE"
    elif [[ $line =~ \"Path\":\"([^\"]+)\" ]]; then
        echo "Path=${BASH_REMATCH[1]}" >> "$CONFIG_FILE"
    elif [[ $line =~ \"Username\":\"([^\"]+)\" ]]; then
        echo "Username=${BASH_REMATCH[1]}" >> "$CONFIG_FILE"
    elif [[ $line =~ \"Password\":\"([^\"]+)\" ]]; then
        echo "Password=${BASH_REMATCH[1]}" >> "$CONFIG_FILE"
    elif [[ $line =~ \"UseLocalPath\":\"([^\"]+)\" ]]; then
        echo "UseLocalPath=${BASH_REMATCH[1]}" >> "$CONFIG_FILE"
    elif [[ $line =~ \"LocalPath\":\"([^\"]+)\" ]]; then
        echo "LocalPath=${BASH_REMATCH[1]}" >> "$CONFIG_FILE"
    elif [[ $line =~ \"MaxImages\":\"([^\"]+)\" ]]; then
        echo "MaxImages=${BASH_REMATCH[1]}" >> "$CONFIG_FILE"
    fi
done

echo "MaxImages=0" >> "$CONFIG_FILE"

echo "Configuration saved to: $CONFIG_FILE"

