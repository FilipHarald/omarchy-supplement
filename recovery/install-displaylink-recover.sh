#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_CONFIG="$REPO_DIR/hyprland-base.conf"

echo "=================================="
echo "DisplayLink recovery"
echo "=================================="

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl is not available. Run this from a Hyprland session."
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl is not available on this system."
    exit 1
fi

if command -v lsusb >/dev/null 2>&1; then
    if lsusb | grep -qiE '17e9|displaylink'; then
        echo "DisplayLink USB device detected."
    else
        echo "Warning: no DisplayLink USB device detected by lsusb."
    fi
fi

echo "Restarting displaylink.service..."
if systemctl restart displaylink.service 2>/dev/null; then
    echo "displaylink.service restarted."
elif sudo -n systemctl restart displaylink.service 2>/dev/null; then
    echo "displaylink.service restarted via sudo."
else
    echo "Could not restart displaylink.service without interactive sudo."
    echo "Run: sudo systemctl restart displaylink.service"
fi

echo "Waiting for reconnect..."
sleep 2

if [ -e /sys/class/drm/card0-DVI-I-1/status ]; then
    echo "DisplayLink DRM connector status: $(cat /sys/class/drm/card0-DVI-I-1/status)"
fi

echo "Triggering DRM hotplug change events..."
if command -v udevadm >/dev/null 2>&1; then
    if udevadm trigger --subsystem-match=drm --action=change 2>/dev/null; then
        echo "DRM hotplug change events triggered."
    elif sudo -n udevadm trigger --subsystem-match=drm --action=change 2>/dev/null; then
        echo "DRM hotplug change events triggered via sudo."
    else
        echo "Could not trigger DRM hotplug events without interactive sudo."
        echo "Run: sudo udevadm trigger --subsystem-match=drm --action=change"
    fi
fi

sleep 1

echo "Reloading Hyprland config..."
hyprctl reload >/dev/null || true

if [ -f "$BASE_CONFIG" ]; then
    echo "Applying monitor lines from $BASE_CONFIG ..."
    while IFS= read -r line; do
        case "$line" in
            monitor=*)
                monitor_value="${line#monitor=}"
                hyprctl keyword monitor "$monitor_value" >/dev/null || true
                ;;
        esac
    done < "$BASE_CONFIG"
else
    echo "Warning: $BASE_CONFIG not found, skipping monitor keyword replay."
fi

echo "Final monitor state:"
hyprctl monitors all

monitor_count="$(hyprctl monitors all | grep -c '^Monitor ' || true)"

if [ "$monitor_count" -ge 3 ]; then
    echo "OK: $monitor_count monitors detected in Hyprland."
    exit 0
fi

echo "Attempting one extra recovery cycle..."
if systemctl restart displaylink.service 2>/dev/null; then
    :
elif sudo -n systemctl restart displaylink.service 2>/dev/null; then
    :
fi
sleep 2
hyprctl reload >/dev/null || true

if [ -f "$BASE_CONFIG" ]; then
    while IFS= read -r line; do
        case "$line" in
            monitor=*)
                monitor_value="${line#monitor=}"
                hyprctl keyword monitor "$monitor_value" >/dev/null || true
                ;;
        esac
    done < "$BASE_CONFIG"
fi

monitor_count="$(hyprctl monitors all | grep -c '^Monitor ' || true)"

if [ "$monitor_count" -ge 3 ]; then
    echo "OK after second cycle: $monitor_count monitors detected in Hyprland."
    hyprctl monitors all
    exit 0
fi

echo "Warning: only $monitor_count monitors detected in Hyprland."
if hyprctl rollinglog 2>/dev/null | grep -q "Failed to update renderer state for /dev/dri/card0"; then
    echo "Hyprland/Aquamarine saw the DisplayLink connector but failed renderer setup for /dev/dri/card0."
    echo "This state usually cannot be fixed by monitor rules; restart Hyprland after saving work."
fi
echo "Helpful checks:"
echo "  - Replug dock USB-C cable"
echo "  - Power-cycle dock"
echo "  - Re-run this script"
echo "  - Check: journalctl -u displaylink.service -n 120 --no-pager"
