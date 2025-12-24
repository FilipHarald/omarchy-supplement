#!/bin/bash

set -e

echo "Installing GNU Stow..."

# Install stow
yay -S --noconfirm --needed stow

echo "Stow installed successfully!"
