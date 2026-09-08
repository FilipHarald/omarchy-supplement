#!/bin/bash

set -euo pipefail

export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMACOACH_ID="io.github.filipharald.omacoach"
OMACOACH_DIR="$HOME/.config/omarchy/plugins/$OMACOACH_ID"

if ! command -v omarchy >/dev/null 2>&1; then
  echo "Omarchy is not installed or is not on PATH."
  exit 1
fi

echo "Installing local Omarchy plugins..."
"$SCRIPT_DIR/install-shell-workspaces.sh"

echo "Installing Omacoach..."
if [ ! -d "$OMACOACH_DIR/.git" ]; then
  omarchy plugin add https://github.com/FilipHarald/omacoach.git --enable --yes
else
  omarchy plugin enable "$OMACOACH_ID"
fi

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  instance_signature="$(hyprctl instances -j 2>/dev/null | jq -r '.[0].instance // empty')"
  if [ -n "$instance_signature" ]; then
    export HYPRLAND_INSTANCE_SIGNATURE="$instance_signature"
  fi
fi
"$OMACOACH_DIR/bin/install-hook"

echo "Omarchy plugins installed successfully."
