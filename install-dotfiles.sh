#!/bin/bash

set -e

REPO_URL="https://github.com/FilipHarald/dotfiles"
REPO_DIR="$HOME/dotfiles"
BASH_ADDITIONS_BLOCK='if [[ -f "$HOME/.config/bash-additions/entry.sh" ]]; then
  source "$HOME/.config/bash-additions/entry.sh"
fi'

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

# Stow all directories except 'legacy'
echo "Stowing dotfiles..."
for dir in "$REPO_DIR"/*/; do
    dirname=$(basename "$dir")
    
    # Skip legacy directory
    if [ "$dirname" = "legacy" ]; then
        echo "Skipping $dirname"
        continue
    fi
    
    echo "Stowing $dirname..."
    stow -v "$dirname"
done

# Stow hidden packages (handled separately)
if [ -d "$REPO_DIR/.foundry" ]; then
    echo "Stowing .foundry..."
    stow -v ".foundry"
fi

# Add bash-additions sourcing to .bashrc if not already present.
# Omarchy upgrades can reset ~/.bashrc, so install-all re-applies this hook.
if [[ -f "$HOME/.bashrc" ]]; then
    if ! grep -q "bash-additions/entry.sh" "$HOME/.bashrc"; then
        printf '\n# Source custom bash additions from dotfiles\n%s\n' "$BASH_ADDITIONS_BLOCK" >> "$HOME/.bashrc"
        echo "Added bash-additions sourcing to ~/.bashrc"
    else
        echo "bash-additions sourcing already present in ~/.bashrc"
    fi
fi

echo "Dotfiles installed successfully!"
echo "NOTE: Your nvim, git, and bash configurations are now active."
