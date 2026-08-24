#!/bin/bash

set -e

echo "Installing Neovim 0.12+ from source..."
echo ""
echo "NOTE: This installs Neovim to /usr/local/bin, which takes"
echo "      precedence over the system package in /usr/bin."
echo "      The system neovim package remains installed to satisfy"
echo "      omarchy-nvim dependency requirements."
echo ""

# Install build dependencies
echo "Installing build dependencies..."
DEPS=(
    base-devel
    cmake
    unzip
    ninja
    curl
    git
)

missing_deps=()
for package in "${DEPS[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 || missing_deps+=("$package")
done

if [ "${#missing_deps[@]}" -gt 0 ]; then
    omarchy pkg add "${missing_deps[@]}"
else
    echo "Build dependencies are already installed."
fi

# Clone neovim if not already present
NVIM_DIR="$HOME/.local/src/neovim"
if [ ! -d "$NVIM_DIR" ]; then
    echo "Cloning Neovim repository..."
    mkdir -p "$HOME/.local/src"
    git clone https://github.com/neovim/neovim "$NVIM_DIR"
else
    echo "Neovim repository already exists, updating..."
    cd "$NVIM_DIR"
    git fetch origin --force refs/tags/nightly:refs/tags/nightly
fi

cd "$NVIM_DIR"

# Checkout nightly
echo "Checking out nightly"
git checkout --detach refs/tags/nightly

# Clean previous builds
echo "Cleaning previous builds..."
make distclean 2>/dev/null || true

# Build and install
echo "Building Neovim (this may take a few minutes)..."
make CMAKE_BUILD_TYPE=Release

echo "Installing Neovim to /usr/local..."
if [ -t 0 ]; then
    sudo make install
else
    pkexec make install
fi

# Verify installation
NVIM_VERSION=$(nvim --version | head -1)
NVIM_PATH=$(which nvim)
echo ""
echo "✓ Neovim installed successfully!"
echo "  Version: $NVIM_VERSION"
echo "  Location: $NVIM_PATH"
echo ""
echo "System neovim package remains installed for omarchy-nvim compatibility."
echo ""
