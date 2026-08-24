#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="local.current-screen-workspaces"
SOURCE_DIR="$SCRIPT_DIR/shell-plugins/current-screen-workspaces"
TARGET_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SHELL_CONFIG="$HOME/.config/omarchy/shell.json"
TS="$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$SOURCE_DIR/manifest.json" ] || [ ! -f "$SOURCE_DIR/Widget.qml" ]; then
  echo "Plugin source is incomplete: $SOURCE_DIR"
  exit 1
fi

omarchy-plugin-validate "$SOURCE_DIR"

if [ ! -f "$SHELL_CONFIG" ]; then
  mkdir -p "$(dirname "$SHELL_CONFIG")"
  cp /usr/share/omarchy/config/omarchy/shell.json "$SHELL_CONFIG"
fi

mkdir -p "$(dirname "$TARGET_DIR")"
if [ -d "$TARGET_DIR" ] && ! diff -qr "$SOURCE_DIR" "$TARGET_DIR" >/dev/null; then
  echo "Plugin changes:"
  diff -ru "$TARGET_DIR" "$SOURCE_DIR" || true
fi
rm -rf "$TARGET_DIR"
cp -R "$SOURCE_DIR" "$TARGET_DIR"

cp "$SHELL_CONFIG" "$SHELL_CONFIG.bak.$TS"
jq --arg id "$PLUGIN_ID" '
  .bar.layout |= with_entries(
    .value |= map(if (type == "object" and .id == "omarchy.workspaces") then .id = $id else . end)
  ) |
  .plugins = ((.plugins // []) | map(select(.id != $id)))
' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp"
if ! cmp -s "$SHELL_CONFIG" "$SHELL_CONFIG.tmp"; then
  echo "Changes for $SHELL_CONFIG:"
  diff -u "$SHELL_CONFIG" "$SHELL_CONFIG.tmp" || true
fi
mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"

if pgrep -x quickshell >/dev/null 2>&1; then
  if ! OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}" omarchy-shell shell rescanPlugins >/dev/null; then
    echo "Plugin files installed, but omarchy-shell could not be rescanned."
  fi
fi

echo "Installed $PLUGIN_ID and replaced omarchy.workspaces in shell.json."
