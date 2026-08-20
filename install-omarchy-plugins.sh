#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v omarchy >/dev/null 2>&1; then
  echo "Omarchy is not installed or is not on PATH."
  exit 1
fi

echo "Installing local Omarchy plugins..."
"$SCRIPT_DIR/install-shell-workspaces.sh"

echo "Omarchy plugins installed successfully."
