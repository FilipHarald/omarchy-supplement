#!/bin/bash

set -euo pipefail

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "hyprctl is not available. Run this from a Hyprland session."
    exit 1
fi

echo "Applying popup-safe laptop scaling..."

# Set the laptop panel to 1.0 scale for Chromium extension popups.
# Keep the normal monitor positions from the base Hyprland config.
hyprctl keyword monitor "eDP-1,1920x1200@59.95,4096x0,1"

echo "Current monitor state:"
hyprctl monitors

echo 'To reset run `bash ~/omarchy-supplement/install-hyprland-base.sh`'
