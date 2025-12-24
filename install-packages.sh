#!/bin/bash

set -e

echo "Installing core system packages..."

# Core development and system packages
PACKAGES=(
    stow
)

yay -S --noconfirm --needed "${PACKAGES[@]}"

echo "Core packages installed successfully!"
