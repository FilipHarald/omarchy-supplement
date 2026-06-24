#!/bin/bash

set -euo pipefail

HYPRLOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
TS="$(date +%Y%m%d-%H%M%S)"

echo "Enabling Hyprlock input animations..."

if [[ ! -f $HYPRLOCK_CONFIG ]]; then
  echo "Hyprlock config not found at $HYPRLOCK_CONFIG"
  echo "Please install Omarchy first"
  exit 1
fi

if awk '
  /^[[:space:]]*animations[[:space:]]*\{/ { in_animations = 1; next }
  in_animations && /^[[:space:]]*enabled[[:space:]]*=[[:space:]]*true[[:space:]]*$/ { found = 1 }
  in_animations && /^[[:space:]]*\}/ { in_animations = 0 }
  END { exit found ? 0 : 1 }
' "$HYPRLOCK_CONFIG"; then
  echo "Hyprlock animations already enabled."
  exit 0
fi

cp "$HYPRLOCK_CONFIG" "$HYPRLOCK_CONFIG.bak.$TS"

awk '
  /^[[:space:]]*animations[[:space:]]*\{/ {
    in_animations = 1
    print
    next
  }

  in_animations && /^[[:space:]]*enabled[[:space:]]*=/ {
    print "    enabled = true"
    next
  }

  in_animations && /^[[:space:]]*\}/ {
    in_animations = 0
    print
    next
  }

  { print }
' "$HYPRLOCK_CONFIG" > "$HYPRLOCK_CONFIG.tmp"
mv "$HYPRLOCK_CONFIG.tmp" "$HYPRLOCK_CONFIG"

echo "Hyprlock input animations enabled."
