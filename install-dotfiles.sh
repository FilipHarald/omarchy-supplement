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
            stow -v "$dirname"
            continue
        fi

        stow -v --adopt "$dirname"

        if ! git diff --quiet -- "$dirname"; then
            echo "WARNING: stow --adopt changed tracked $dirname dotfiles."
            git diff -- "$dirname"
            echo "Commit or revert the diff, then rerun: stow -v --dir=$REPO_DIR --target=$HOME $dirname"
            exit 1
        fi

        continue
    fi

    stow -v "$dirname"
done

# Stow hidden packages (handled separately)
if [ -d "$REPO_DIR/.foundry" ]; then
    echo "Stowing .foundry..."
    stow -v ".foundry"
fi

# Migrate the pre-v4 Omarchy bootstrap without disturbing user additions.
if grep -Fq 'source ~/.local/share/omarchy/default/bash/rc' "$HOME/.bashrc"; then
    cp "$HOME/.bashrc" "$HOME/.bashrc.bak.$(date +%Y%m%d-%H%M%S)"
    sed -i 's|source ~/.local/share/omarchy/default/bash/rc|source "$OMARCHY_PATH/default/bash/rc"|' "$HOME/.bashrc"
    if ! grep -Fq '/usr/share/omarchy/default/bash/env-bootstrap' "$HOME/.bashrc"; then
        sed -i '1i[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] \&\& source /usr/share/omarchy/default/bash/env-bootstrap\n' "$HOME/.bashrc"
    fi
    echo "Migrated ~/.bashrc to the Omarchy v4 bootstrap."
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
