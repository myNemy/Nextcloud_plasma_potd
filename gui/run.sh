#!/bin/bash
# Simple launcher for Nextcloud Wallpaper Configuration GUI

# Enable XMLHttpRequest for local files
export QML_XHR_ALLOW_FILE_READ=1

# Pass HOME directory as environment variable
export QML_HOME_DIR="$HOME"

# Create a temporary file with home path for QML to read
echo "$HOME" > /tmp/qml_home_path.txt

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

