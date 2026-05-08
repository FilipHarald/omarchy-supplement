#!/bin/bash

set -euo pipefail

HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"
MONITORS_CONFIG="$HOME/.config/hypr/monitors.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_CONFIG="$SCRIPT_DIR/hyprland-base.conf"
SOURCE_LINE="source = $BASE_CONFIG"
TS="$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$HYPRLAND_CONFIG" ]; then
    echo "Hyprland config not found at $HYPRLAND_CONFIG"
    echo "Please install hyprland first"
    exit 1
fi

if [ ! -f "$BASE_CONFIG" ]; then
    echo "Base config not found at $BASE_CONFIG"
    exit 1
fi

echo "Creating backups..."
cp "$HYPRLAND_CONFIG" "$HYPRLAND_CONFIG.bak.$TS"
if [ -f "$MONITORS_CONFIG" ]; then
    cp "$MONITORS_CONFIG" "$MONITORS_CONFIG.bak.$TS"
fi

echo "Normalizing source line in $HYPRLAND_CONFIG..."
if grep -Fq "$SOURCE_LINE" "$HYPRLAND_CONFIG"; then
    awk -v line="$SOURCE_LINE" '
        $0 == line {
            if (!seen++) print
            next
        }
        { print }
    ' "$HYPRLAND_CONFIG" > "$HYPRLAND_CONFIG.tmp"
    mv "$HYPRLAND_CONFIG.tmp" "$HYPRLAND_CONFIG"
else
    printf "\n%s\n" "$SOURCE_LINE" >> "$HYPRLAND_CONFIG"
fi

echo "Removing inline monitor entries from hyprland.conf..."
awk '
    /^[[:space:]]*monitor[[:space:]]*=/ { next }
    { print }
' "$HYPRLAND_CONFIG" > "$HYPRLAND_CONFIG.tmp"
mv "$HYPRLAND_CONFIG.tmp" "$HYPRLAND_CONFIG"

if [ -f "$MONITORS_CONFIG" ]; then
    echo "Keeping Omarchy generic auto-monitor rule enabled for hotplug recovery..."
    awk '
        /^[[:space:]]*#[[:space:]]*Disabled by omarchy-supplement install-hyprland-base\.sh[[:space:]]*$/ {
            restore_next_auto = 1
            next
        }
        /^[[:space:]]*#[[:space:]]*monitor=,[[:space:]]*preferred,[[:space:]]*auto,[[:space:]]*1[[:space:]]*$/ {
            if (restore_next_auto) {
                print "monitor=,preferred,auto,1"
                restore_next_auto = 0
                next
            }
            print
            next
        }
        { restore_next_auto = 0; print }
    ' "$MONITORS_CONFIG" > "$MONITORS_CONFIG.tmp"
    mv "$MONITORS_CONFIG.tmp" "$MONITORS_CONFIG"
fi

echo "Reloading Hyprland configuration..."
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null || true
fi

echo "Hyprland base configuration setup complete."
