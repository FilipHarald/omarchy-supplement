#!/bin/bash

set -e

PUBLIC_REPO_URL="git@github.com:FilipHarald/ai-public.git"
PRIVATE_REPO_URL="git@github.com:FilipHarald/ai-private.git"
PUBLIC_REPO_DIR="$HOME/c/ai-public"
PRIVATE_REPO_DIR="$HOME/c/ai-private"

echo "Setting up AI workflow assets..."

if ! command -v stow &>/dev/null; then
    echo "Stow is not installed. Please run ./install-stow.sh first."
    exit 1
fi

clone_or_pull() {
    local repo_url="$1"
    local repo_dir="$2"
    local name="$3"

    if [ -d "$repo_dir/.git" ]; then
        echo "$name repository already exists at $repo_dir"
        echo "Pulling latest changes..."
        git -C "$repo_dir" pull
    elif [ -d "$repo_dir" ]; then
        echo "$name directory exists at $repo_dir but is not a git repository. Skipping clone."
    else
        echo "Cloning $name repository..."
        mkdir -p "$(dirname "$repo_dir")"
        git clone "$repo_url" "$repo_dir"
    fi
}

run_stow_script() {
    local repo_dir="$1"
    local name="$2"

    if [ ! -x "$repo_dir/stow.sh" ]; then
        echo "Missing executable stow script: $repo_dir/stow.sh"
        exit 1
    fi

    echo "Stowing $name assets..."
    "$repo_dir/stow.sh"
}

clone_or_pull "$PUBLIC_REPO_URL" "$PUBLIC_REPO_DIR" "ai-public"
clone_or_pull "$PRIVATE_REPO_URL" "$PRIVATE_REPO_DIR" "ai-private"

run_stow_script "$PUBLIC_REPO_DIR" "ai-public"
run_stow_script "$PRIVATE_REPO_DIR" "ai-private"

echo "AI workflow assets installed successfully!"
