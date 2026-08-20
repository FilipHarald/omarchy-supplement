#!/bin/bash

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================="
echo "Installing omarchy-supplement"
echo "=================================="
echo ""

# Install all packages in order
echo "Installing core packages..."
"$SCRIPT_DIR/install-packages.sh"
echo ""

echo "Installing GNU Stow..."
"$SCRIPT_DIR/install-stow.sh"
echo ""

echo "Installing Neovim from source..."
"$SCRIPT_DIR/install-neovim.sh"
echo ""

echo "Setting up dotfiles..."
"$SCRIPT_DIR/install-dotfiles.sh"
echo ""

echo "Setting up AI workflow assets..."
"$SCRIPT_DIR/install-ai-assets.sh"
echo ""

echo "Configuring npm global packages..."
"$SCRIPT_DIR/install-npm-config.sh"
echo ""

echo "Setting up Hyprland base configuration..."
"$SCRIPT_DIR/install-hyprland-base.sh"
echo ""

echo "Installing Omarchy plugins..."
"$SCRIPT_DIR/install-omarchy-plugins.sh"
echo ""

echo "=================================="
echo "Installation complete!"
echo "=================================="
echo ""
echo "IMPORTANT NOTES:"
echo "- Log out and log back in for docker group membership to take effect"
echo "- Syncthing is running at http://127.0.0.1:8384"
echo "- Your nvim configuration will auto-install plugins on first launch"
if [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
  echo "- npm globals are managed by nvm"
else
  echo "- npm global packages are configured under ~/.local/npm"
fi
echo "- Waybar tweaks are not applied by default on Quickshell-based Omarchy"
echo ""
