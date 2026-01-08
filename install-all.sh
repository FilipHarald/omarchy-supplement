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

echo "Configuring npm global packages..."
"$SCRIPT_DIR/install-npm-config.sh"
echo ""

echo "Setting up Hyprland base configuration..."
"$SCRIPT_DIR/install-hyprland-base.sh"
echo ""

echo "Applying Waybar tweaks..."
"$SCRIPT_DIR/install-waybar-tweaks.sh"
echo ""

echo "=================================="
echo "Installation complete!"
echo "=================================="
echo ""
echo "IMPORTANT NOTES:"
echo "- Log out and log back in for docker group membership to take effect"
echo "- Syncthing is running at http://127.0.0.1:8384"
echo "- Your nvim configuration will auto-install plugins on first launch"
echo "- npm global packages are configured to install to ~/.local/npm"
echo ""
