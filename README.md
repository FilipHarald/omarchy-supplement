# omarchy-supplement

Reproducible development environment setup for omarchy (Arch Linux), using modular bash scripts.

## Quick Start

Run all installation scripts:
```bash
cd ~/omarchy-supplement
chmod +x *.sh
./install-all.sh
```

Or run individual scripts as needed:
```bash
./install-neovim.sh
./install-dotfiles.sh
./install-hyprland-base.sh
./install-waybar-tweaks.sh
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `install-all.sh` | Run all installation scripts in order |
| `install-packages.sh` | Install core system packages |
| `install-stow.sh` | Install GNU Stow |
| `install-neovim.sh` | Build and install Neovim nightly from source |
| `install-dotfiles.sh` | Clone and stow dotfiles from your repository |
| `install-hyprland-base.sh` | Apply Hyprland configuration |
| `install-waybar-tweaks.sh` | Apply Waybar customizations |

## Update Scripts

Located in the `update/` directory:

| Script | Purpose |
|--------|---------|
| `update-neovim.sh` | Update to latest Neovim nightly |
| `update-neovim-specific.sh` | Install a specific Neovim version |

## Notes

- All scripts use `set -e` to exit on first error
- Scripts are idempotent - safe to run multiple times
- Check individual scripts for details on what they install/configure
