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
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `install-all.sh` | Run all installation scripts in order |
| `install-packages.sh` | Install core system packages |
| `install-stow.sh` | Install GNU Stow |
| `install-neovim.sh` | Build and install Neovim nightly from source |
| `install-dotfiles.sh` | Clone and stow dotfiles from your repository |
| `install-docker-ufw-forwarding.sh` | Allow Docker bridge containers to reach the internet through UFW |
| `install-hyprland-base.sh` | Apply Omarchy Quattro Hyprland Lua configuration |
| `install-hyprlock-animation.sh` | Enable lock screen input animations |
| `install-shell-workspaces.sh` | Install Quickshell workspace widget showing only the current screen |
| `install-waybar-tweaks.sh` | Apply legacy Waybar customizations; not used by Quickshell Omarchy |

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

## DisplayLink / Monitor Configuration Notes

- Keep Omarchy's generic Hyprland monitor rule enabled in `~/.config/hypr/monitors.lua`:
  ```lua
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
  ```
- DisplayLink hotplug depends on Hyprland first auto-discovering the `evdi` output. Explicit `desc:` monitor rules in `hypr/monitors.lua` should refine the layout after discovery, not replace the generic rule.
- If Hyprmon disappears from the Omarchy launcher after desktop entry changes, refresh the launcher cache with:
  ```bash
  omarchy restart walker
  ```
- Avoid custom Hyprmon launcher overrides unless the stock `/usr/share/applications/hyprmon.desktop` is actually broken.

## Omarchy Quattro / Hyprland Lua Notes

- `install-hyprland-base.sh` copies the supplement's Lua modules from `hypr/` into `~/.config/hypr/`.
- Omarchy's `~/.config/hypr/hyprland.lua` loads these modules with `require("hypr.monitors")`, `require("hypr.input")`, `require("hypr.bindings")`, and `require("hypr.looknfeel")`.
- If a legacy `~/.config/hypr/hyprland.conf` exists, the installer moves it aside so Hyprland uses the Lua config.
- `hyprland-base.conf` and `hyprland-looknfeel-compat.conf` are legacy references for the old `.conf` setup.

## DisplayLink Resume Recovery Notes

- Keep Omarchy's generic `hl.monitor({ output = "", mode = "preferred", position = "auto", ... })` rule enabled so Hyprland can auto-discover DisplayLink outputs after hotplug or resume.
- Do not pin `AQ_DRM_DEVICES` in Hyprland config. On this laptop it made reboot behavior worse and could leave displays unavailable.
- `recovery/install-displaylink-recover.sh` restarts `displaylink.service`, triggers DRM hotplug change events, reloads Hyprland, and replays monitor rules.
- If recovery reports `Failed to update renderer state for /dev/dri/card0`, Hyprland/Aquamarine saw the DisplayLink connector but failed renderer setup. In that state monitor rules are not enough; save work and restart Hyprland.
