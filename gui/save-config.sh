#!/bin/bash
# Helper script to save configuration from GUI

CONFIG_DIR="$HOME/.config/plasma_engine_potd"
CONFIG_FILE="$CONFIG_DIR/nextcloudprovider.conf"

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" << 'EOF'
[Nextcloud]
Url=
Path=
Username=
Password=
UseLocalPath=false
LocalPath=
MaxImages=0
EOF

echo "Configuration file template created at: $CONFIG_FILE"
echo "Please edit it manually or use the GUI to configure values."

