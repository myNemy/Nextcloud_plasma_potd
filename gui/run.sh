#!/bin/bash
# Simple launcher for Nextcloud Wallpaper Configuration GUI

# Enable XMLHttpRequest for local files
export QML_XHR_ALLOW_FILE_READ=1

# Pass HOME directory as environment variable
export QML_HOME_DIR="$HOME"

# Create a temporary file with home path for QML to read
echo "$HOME" > /tmp/qml_home_path.txt

# Function to execute save command in background
# This will be called by writing to a trigger file
execute_save_background() {
    local trigger_file="/tmp/nextcloud_save_trigger.txt"
    
    if [ -f "$trigger_file" ]; then
        local config_text=$(cat "$trigger_file" | head -n -1)
        local script_path=$(cat "$trigger_file" | tail -n 1)
        
        # Execute save
        echo "$config_text" | bash "$script_path"
        
        # Remove trigger file
        rm -f "$trigger_file"
    fi
}

# Monitor trigger file in background
(
    while true; do
        if [ -f "/tmp/nextcloud_save_trigger.txt" ]; then
            execute_save_background
        fi
        sleep 0.1
    done
) &
MONITOR_PID=$!

# Cleanup monitor on exit
cleanup_monitor() {
    kill $MONITOR_PID 2>/dev/null
}
trap cleanup_monitor EXIT

# Cleanup function
cleanup() {
    rm -f /tmp/qml_home_path.txt
}
trap cleanup EXIT

# Try different QML runners (prefer qml6)
if command -v qml6 &> /dev/null; then
    qml6 main.qml "$HOME"
elif command -v qmlscene &> /dev/null; then
    qmlscene main.qml "$HOME"
elif command -v qml &> /dev/null; then
    qml main.qml "$HOME"
else
    echo "Error: No QML runner found. Please install qt6-declarative or qt5-declarative" >&2
    exit 1
fi

