#!/bin/bash
# Script to clear Nextcloud wallpaper cache before restarting Plasma
# This ensures potd will fetch a new random image instead of using cached one

CACHE_DIR="$HOME/.cache/plasma_engine_potd"
CACHE_FILE="$CACHE_DIR/nextcloud"
CACHE_JSON="$CACHE_FILE.json"

# Remove cache files
if [ -f "$CACHE_FILE" ]; then
    rm -f "$CACHE_FILE"
    echo "Deleted cache file: $CACHE_FILE"
fi

if [ -f "$CACHE_JSON" ]; then
    rm -f "$CACHE_JSON"
    echo "Deleted cache JSON: $CACHE_JSON"
fi

echo "Cache cleared. Restarting Plasma..."
killall plasmashell && kstart plasmashell

