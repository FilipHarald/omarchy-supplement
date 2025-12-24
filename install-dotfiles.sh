#!/bin/bash

set -e

REPO_URL="https://github.com/FilipHarald/dotfiles"
REPO_DIR="$HOME/dotfiles"

echo "Setting up dotfiles..."

# Check if stow is installed
if ! command -v stow &>/dev/null; then
    echo "Stow is not installed. Please run ./install-stow.sh first."
    exit 1
fi

# Clone dotfiles repository if it doesn't exist
if [ -d "$REPO_DIR" ]; then
    echo "Dotfiles repository already exists at $REPO_DIR"
    echo "Pulling latest changes..."
    cd "$REPO_DIR"
    git pull
else
    echo "Cloning dotfiles repository..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Remove existing bashrc to avoid conflicts
if [ -f "$HOME/.bashrc" ]; then
    echo "Removing existing ~/.bashrc"
    rm "$HOME/.bashrc"
fi

# Stow configurations
echo "Stowing dotfiles..."
stow -v nvim2
stow -v git

echo "Dotfiles installed successfully!"
echo "NOTE: Your bash, nvim (nvim2), and git configurations are now active."
