#!/bin/bash

set -e

echo "Installing core system packages..."

# Core development and system packages
PACKAGES=(
    stow
)

missing_packages=()
for package in "${PACKAGES[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 || missing_packages+=("$package")
done

if [ "${#missing_packages[@]}" -gt 0 ]; then
    yay -S --noconfirm --needed "${missing_packages[@]}"
else
    echo "Core packages are already installed."
fi

echo "Core packages installed successfully!"
