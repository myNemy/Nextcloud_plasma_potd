#!/bin/bash
# Helper to read config and output as JSON for QML

CONFIG_FILE="$HOME/.config/plasma_engine_potd/nextcloudprovider.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "{}"
    exit 0
fi

# Simple INI to JSON converter
awk -F'=' '
BEGIN {
    print "{"
    first=1
}
/^\[Nextcloud\]/ {
    in_section=1
    next
}
/^\[/ {
    in_section=0
    next
}
in_section && /^[^#]/ && /=/ {
    key=$1
    gsub(/^[ \t]+|[ \t]+$/, "", key)
    value=$2
    gsub(/^[ \t]+|[ \t]+$/, "", value)
    if (!first) print ","
    first=0
    printf "  \"%s\": \"%s\"", key, value
}
END {
    print "\n}"
}
' "$CONFIG_FILE"

