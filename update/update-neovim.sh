#!/bin/bash

set -e

echo "Updating Neovim to latest nightly..."
echo ""

NVIM_DIR="$HOME/.local/src/neovim"

# Check if neovim source exists
if [ ! -d "$NVIM_DIR" ]; then
    echo "ERROR: Neovim source directory not found at $NVIM_DIR"
    echo "Please run install-neovim.sh first."
    exit 1
fi

cd "$NVIM_DIR"

# Show current version
CURRENT_VERSION=$(nvim --version | head -1)
echo "Current version: $CURRENT_VERSION"
echo ""

# Fetch latest updates
echo "Fetching latest updates from GitHub..."
git fetch --all

# Checkout nightly
echo "Checking out nightly..."
git checkout nightly
git pull origin nightly

# Clean previous builds
echo "Cleaning previous builds..."
make distclean 2>/dev/null || true

# Build
echo "Building Neovim (this may take a few minutes)..."
make CMAKE_BUILD_TYPE=Release

# Install
echo "Installing to /usr/local..."
sudo make install

# Verify
NEW_VERSION=$(nvim --version | head -1)
echo ""
echo "✓ Neovim updated successfully!"
echo "  Previous: $CURRENT_VERSION"
echo "  Current:  $NEW_VERSION"
echo ""
