#!/bin/bash

set -e

echo "Installing GNU Stow..."

# Install stow only when it is missing, avoiding unnecessary authentication.
if ! pacman -Q stow >/dev/null 2>&1; then
    omarchy pkg add stow
else
    echo "GNU Stow is already installed."
fi

echo "Stow installed successfully!"
