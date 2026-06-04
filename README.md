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
| `install-docker-ufw-forwarding.sh` | Allow Docker bridge containers to reach the internet through UFW |
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

## DisplayLink / Monitor Configuration Notes

- Keep Omarchy's generic Hyprland monitor rule enabled in `~/.config/hypr/monitors.conf`:
  ```conf
  monitor=,preferred,auto,1
  ```
- DisplayLink hotplug depends on Hyprland first auto-discovering the `evdi` output. Explicit `desc:` monitor rules in `hyprland-base.conf` should refine the layout after discovery, not replace the generic rule.
- If Hyprmon disappears from the Omarchy launcher after desktop entry changes, refresh the launcher cache with:
  ```bash
  omarchy restart walker
  ```
- Avoid custom Hyprmon launcher overrides unless the stock `/usr/share/applications/hyprmon.desktop` is actually broken.

## Omarchy 3.8.1 / Hyprland 0.55 Notes

- `install-hyprland-base.sh` generates `hyprland-looknfeel-compat.conf` from Omarchy's current default `looknfeel.conf` and points `~/.config/hypr/hyprland.conf` at it.
- The generated file fixes Hyprland 0.55 parse errors from Omarchy 3.8.1 defaults: locked group border colors can no longer be `-1`, and `dwindle:pseudotile` was removed.
- The custom split-toggle binding uses `layoutmsg, togglesplit`, matching the updated Omarchy tiling binding format.

## DisplayLink Resume Recovery Notes

- Keep Omarchy's generic `monitor=,preferred,auto,1` rule enabled so Hyprland can auto-discover DisplayLink outputs after hotplug or resume.
- Do not pin `AQ_DRM_DEVICES` in Hyprland config. On this laptop it made reboot behavior worse and could leave displays unavailable.
- `recovery/install-displaylink-recover.sh` restarts `displaylink.service`, triggers DRM hotplug change events, reloads Hyprland, and replays monitor rules.
- If recovery reports `Failed to update renderer state for /dev/dri/card0`, Hyprland/Aquamarine saw the DisplayLink connector but failed renderer setup. In that state monitor rules are not enough; save work and restart Hyprland.
