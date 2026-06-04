#!/bin/bash

set -euo pipefail

HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"
MONITORS_CONFIG="$HOME/.config/hypr/monitors.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_CONFIG="$SCRIPT_DIR/hyprland-base.conf"
SOURCE_LINE="source = $BASE_CONFIG"
DEFAULT_LOOKNFEEL="$HOME/.local/share/omarchy/default/hypr/looknfeel.conf"
DEFAULT_LOOKNFEEL_SOURCE="source = ~/.local/share/omarchy/default/hypr/looknfeel.conf"
COMPAT_LOOKNFEEL="$SCRIPT_DIR/hyprland-looknfeel-compat.conf"
COMPAT_LOOKNFEEL_SOURCE="source = $COMPAT_LOOKNFEEL"
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

if [ ! -f "$DEFAULT_LOOKNFEEL" ]; then
    echo "Omarchy default looknfeel config not found at $DEFAULT_LOOKNFEEL"
    exit 1
fi

echo "Creating backups..."
cp "$HYPRLAND_CONFIG" "$HYPRLAND_CONFIG.bak.$TS"
if [ -f "$MONITORS_CONFIG" ]; then
    cp "$MONITORS_CONFIG" "$MONITORS_CONFIG.bak.$TS"
fi

echo "Generating Hyprland 0.55-compatible looknfeel config..."
awk '
    /^[[:space:]]*col\.border_locked_active[[:space:]]*=[[:space:]]*-1[[:space:]]*$/ {
        print "    col.border_locked_active = $activeBorderColor"
        next
    }
    /^[[:space:]]*col\.border_locked_inactive[[:space:]]*=[[:space:]]*-1[[:space:]]*$/ {
        print "    col.border_locked_inactive = $inactiveBorderColor"
        next
    }
    /^[[:space:]]*pseudotile[[:space:]]*=/ {
        print "    # Hyprland 0.55 removed dwindle:pseudotile; use the pseudo dispatcher per window."
        next
    }
    { print }
' "$DEFAULT_LOOKNFEEL" > "$COMPAT_LOOKNFEEL.tmp"
mv "$COMPAT_LOOKNFEEL.tmp" "$COMPAT_LOOKNFEEL"

echo "Clearing stale AQ_DRM_DEVICES from user service environment..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user unset-environment AQ_DRM_DEVICES 2>/dev/null || true
fi

echo "Using compatible Omarchy looknfeel config in $HYPRLAND_CONFIG..."
awk -v default_line="$DEFAULT_LOOKNFEEL_SOURCE" -v compat_line="$COMPAT_LOOKNFEEL_SOURCE" '
    $0 == default_line || $0 == compat_line {
        if (!seen++) print compat_line
        next
    }
    { print }
' "$HYPRLAND_CONFIG" > "$HYPRLAND_CONFIG.tmp"
mv "$HYPRLAND_CONFIG.tmp" "$HYPRLAND_CONFIG"

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
