#!/bin/bash

set -e

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo ""
    echo "Example: $0 v0.12.0"
    echo ""
    echo "Available versions:"
    
    NVIM_DIR="$HOME/.local/src/neovim"
    if [ -d "$NVIM_DIR" ]; then
        cd "$NVIM_DIR"
        git fetch origin --tags --force 2>/dev/null
        echo ""
        git tag -l 'v0.1*' | sort -V | tail -10
    else
        echo "ERROR: Neovim source not found at $NVIM_DIR"
        echo "Please run install-neovim.sh first."
    fi
    echo ""
    exit 1
fi

VERSION="$1"
NVIM_DIR="$HOME/.local/src/neovim"

if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Expected a release tag such as v0.12.0."
    exit 1
fi

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

# Fetch latest tags
echo "Fetching latest updates from GitHub..."
git fetch origin --tags --force

# Check if version exists
if ! git rev-parse --verify "refs/tags/$VERSION^{commit}" >/dev/null 2>&1; then
    echo "ERROR: Version $VERSION not found."
    echo ""
    echo "Available versions:"
    git tag -l 'v0.1*' | sort -V | tail -10
    exit 1
fi

# Checkout specified version
echo "Checking out $VERSION..."
git checkout --detach "refs/tags/$VERSION"

# Clean previous builds
echo "Cleaning previous builds..."
make distclean 2>/dev/null || true

# Build
echo "Building Neovim (this may take a few minutes)..."
make CMAKE_BUILD_TYPE=Release

# Install
echo "Installing to /usr/local..."
if [ -t 0 ]; then
    sudo make install
else
    pkexec make install
fi

# Verify
NEW_VERSION=$(nvim --version | head -1)
echo ""
echo "✓ Neovim updated successfully!"
echo "  Previous: $CURRENT_VERSION"
echo "  Current:  $NEW_VERSION"
echo ""
