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

echo "Syncing Omarchy internal monitor scale state..."
internal_monitor_scale="$(
  python - "$TARGET_DIR/monitors.lua" <<'PY'
import re
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()

block = re.search(r'hl\.monitor\s*\(\s*\{(?=[^}]*output\s*=\s*["\']eDP-[^"\']*["\'])(.*?)\}\s*\)', text, re.S)
if block:
    scale = re.search(r'scale\s*=\s*([0-9]+(?:\.[0-9]+)?)', block.group(1))
    if scale:
        print(scale.group(1))
        raise SystemExit(0)

fallback = re.search(r'^\s*local\s+omarchy_monitor_scale\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*$', text, re.M)
if fallback:
    print(fallback.group(1))
PY
)"

if [ -n "$internal_monitor_scale" ]; then
  mkdir -p "$HOME/.local/state/omarchy/toggles/hypr"
  printf '%s\n' "$internal_monitor_scale" > "$HOME/.local/state/omarchy/toggles/hypr/internal-monitor-scale"
  echo "- internal-monitor-scale = $internal_monitor_scale"
else
  echo "- no eDP/internal monitor scale found in monitors.lua; leaving Omarchy state unchanged"
fi

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
