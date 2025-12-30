#!/bin/bash

set -e

echo "Setting up npm global configuration..."

# Create npm global directory if it doesn't exist
NPM_GLOBAL_DIR="$HOME/.local/npm"
if [ ! -d "$NPM_GLOBAL_DIR" ]; then
    echo "Creating npm global directory at $NPM_GLOBAL_DIR"
    mkdir -p "$NPM_GLOBAL_DIR"
else
    echo "npm global directory already exists at $NPM_GLOBAL_DIR"
fi

# Configure npm to use the user-level global directory
if command -v npm &>/dev/null; then
    echo "Configuring npm prefix to $NPM_GLOBAL_DIR"
    npm config set prefix "$NPM_GLOBAL_DIR"
    echo "npm configuration complete!"
else
    echo "WARNING: npm is not installed. Install npm and re-run this script."
    echo "The PATH configuration in bash-additions/npm.sh will still work once npm is installed."
fi

echo "npm global packages will be installed to: $NPM_GLOBAL_DIR"
echo "PATH configuration is managed by dotfiles/bash-additions/npm.sh"
