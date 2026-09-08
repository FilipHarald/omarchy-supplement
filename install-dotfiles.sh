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
if [ -d "$REPO_DIR/.git" ]; then
    echo "Dotfiles repository already exists at $REPO_DIR"
    echo "Pulling latest changes..."
    cd "$REPO_DIR"
    git pull --ff-only
elif [ -e "$REPO_DIR" ]; then
    echo "$REPO_DIR exists but is not a Git repository."
    exit 1
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
    if [ "$dirname" = "nvim" ]; then
        echo "Removing default nvim configuration..."
        rm -rf "$HOME/.config/nvim"
    fi

    if [ "$dirname" = "opencode" ] || [ "$dirname" = "starship" ]; then
        if ! git diff --quiet -- "$dirname" || ! git diff --cached --quiet -- "$dirname"; then
            echo "$dirname has tracked local changes; stowing without --adopt."
            stow -v --restow --no-folding --target="$HOME" --dir="$REPO_DIR" "$dirname"
            continue
        fi

        stow -v --adopt --no-folding --target="$HOME" --dir="$REPO_DIR" "$dirname"

        if ! git diff --quiet -- "$dirname"; then
            echo "WARNING: stow --adopt changed tracked $dirname dotfiles."
            git diff -- "$dirname"
            echo "Commit or revert the diff, then rerun: stow -v --dir=$REPO_DIR --target=$HOME $dirname"
            exit 1
        fi

        continue
    fi

    stow -v --restow --no-folding --target="$HOME" --dir="$REPO_DIR" "$dirname"
done

echo "Dotfiles installed successfully!"
echo "NOTE: Stow-managed configuration is now active; mise owns ~/.bashrc and ~/.gitconfig."
