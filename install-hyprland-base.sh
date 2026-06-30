#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/hypr"
TARGET_DIR="$HOME/.config/hypr"
TS="$(date +%Y%m%d-%H%M%S)"

files=(
  monitors.lua
  input.lua
  bindings.lua
  looknfeel.lua
)

if [ ! -f "$TARGET_DIR/hyprland.lua" ]; then
  echo "Hyprland Lua config not found at $TARGET_DIR/hyprland.lua"
  echo "Run Omarchy Quattro/dev setup first."
  exit 1
fi

for file in "${files[@]}"; do
  if [ ! -f "$SOURCE_DIR/$file" ]; then
    echo "Supplement Hyprland config not found: $SOURCE_DIR/$file"
    exit 1
  fi
done

echo "Installing Omarchy Lua Hyprland overrides..."
mkdir -p "$TARGET_DIR"

for file in "${files[@]}"; do
  target="$TARGET_DIR/$file"
  if [ -f "$target" ]; then
    cp "$target" "$target.bak.$TS"
  fi

  cp "$SOURCE_DIR/$file" "$target"
  echo "- $target"
done

if [ -f "$TARGET_DIR/hyprland.conf" ]; then
  echo "Moving legacy hyprland.conf aside so Hyprland loads hyprland.lua..."
  mv "$TARGET_DIR/hyprland.conf" "$TARGET_DIR/hyprland.conf.bak.$TS"
fi

echo "Clearing stale AQ_DRM_DEVICES from user service environment..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user unset-environment AQ_DRM_DEVICES 2>/dev/null || true
fi

echo "Reloading Hyprland configuration..."
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null || true
  hyprctl configerrors || true
fi

echo "Hyprland Lua configuration setup complete."
