#!/bin/bash
# Simple launcher for Nextcloud Wallpaper Configuration GUI

# Try different QML runners
if command -v qml6 &> /dev/null; then
    qml6 main.qml
elif command -v qmlscene &> /dev/null; then
    qmlscene main.qml
elif command -v qml &> /dev/null; then
    qml main.qml
else
    echo "Error: No QML runner found. Please install qt6-declarative or qt5-declarative"
    exit 1
fi

