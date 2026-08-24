#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/hypr"
TARGET_DIR="$HOME/.config/hypr"
TS="$(date +%Y%m%d-%H%M%S)"

files=(
  input.lua
  bindings.lua
  looknfeel.lua
)

host_name="$(hostname -s)"
if [ "$host_name" = "decem" ]; then
  files+=(monitors.lua)
fi

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
    if ! cmp -s "$SOURCE_DIR/$file" "$target"; then
      echo "Changes for $target:"
      diff -u "$target" "$SOURCE_DIR/$file" || true
    fi
    cp "$target" "$target.bak.$TS"
  fi

  cp "$SOURCE_DIR/$file" "$target"
  echo "- $target"
done

if [ "$host_name" = "decem" ]; then
  echo "- $TARGET_DIR/monitors.lua was installed for host decem"
else
  echo "- $TARGET_DIR/monitors.lua is decem-specific and was skipped on host $host_name"
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
if command -v hyprctl >/dev/null 2>&1 && hyprctl instances 2>/dev/null | grep -q '^instance '; then
  hyprctl_args=()
  if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl_args=(-i 0)
  fi

  hyprctl "${hyprctl_args[@]}" reload >/dev/null
  errors="$(hyprctl "${hyprctl_args[@]}" configerrors)"
  if [ -n "$errors" ]; then
    printf '%s\n' "$errors" >&2
    exit 1
  fi
fi

echo "Hyprland Lua configuration setup complete."
