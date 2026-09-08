# omarchy-supplement

Reproducible development environment setup for omarchy (Arch Linux), using modular bash scripts.

## Quick Start

Run the default supported installation sequence:
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
./install-omarchy-plugins.sh
./check.sh
```

## Available Scripts

| Script | Purpose |
|--------|---------|
| `install-all.sh` | Run the supported installation scripts in order |
| `install-packages.sh` | Install core system packages |
| `install-stow.sh` | Install GNU Stow |
| `install-neovim.sh` | Build and install Neovim nightly from source |
| `install-dotfiles.sh` | Clone and stow dotfiles from your repository |
| `install-mise-profile.sh` | Select the hostname as the mise history watcher profile |
| `install-ai-assets.sh` | Clone/pull and stow `ai-public` and `ai-private` workflow assets |
| `install-npm-config.sh` | Configure npm globals when Node is not managed by nvm |
| `install-hyprland-base.sh` | Apply Omarchy Quattro Hyprland Lua configuration |
| `install-hyprlock-animation.sh` | Configure standalone Hyprlock; Omarchy 4 uses its Quickshell lock screen |
| `install-shell-workspaces.sh` | Install Quickshell workspace widget showing only the current screen, with active workspaces bold dark green and urgent workspaces bold red |
| `install-omarchy-plugins.sh` | Install the current-screen workspace widget and Omacoach with its Hyprland bindings |
| `check.sh` | Check repositories, Stow packages, portable Hyprland config, plugins, and secrets without changing them |
| `install-waybar-tweaks.sh` | Retired on Omarchy 4, which uses Quickshell instead of Waybar |

## Update Scripts

## Testing Urgent Workspaces

`notify-send` does not mark a workspace urgent. It only shows a notification popup.

Run this in a terminal on the workspace you want to turn red, and switch away before the sleep finishes. This depends on the terminal translating BEL into an urgency request:

```bash
sleep 5; printf '\a'
```

Located in the `update/` directory:

| Script | Purpose |
|--------|---------|
| `update-neovim.sh` | Update to latest Neovim nightly |
| `update-neovim-specific.sh` | Install a specific Neovim version |

## Notes

- All scripts use `set -e` to exit on first error
- Scripts are intended to be rerunnable; review backups and local repository state first
- Check individual scripts for details on what they install/configure

## DisplayLink / Monitor Configuration Notes

- Keep Omarchy's generic Hyprland monitor rule enabled in `~/.config/hypr/monitors.lua`:
  ```lua
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
  ```
- DisplayLink hotplug depends on Hyprland first auto-discovering the `evdi` output. Explicit `desc:` monitor rules in `hypr/monitors.lua` should refine the layout after discovery, not replace the generic rule.
- If Hyprmon disappears from the Omarchy launcher after desktop entry changes, refresh the launcher cache with:
  ```bash
  omarchy restart shell
  ```
- Avoid custom Hyprmon launcher overrides unless the stock `/usr/share/applications/hyprmon.desktop` is actually broken.

## Omarchy Quattro / Hyprland Lua Notes

- `install-hyprland-base.sh` copies the portable `bindings.lua` and `looknfeel.lua` modules from `hypr/` into `~/.config/hypr/` and shows their diffs first.
- Host-specific monitor layout sources are tracked by mise profiles instead of this repository. Decem uses `one-screen` and `two-screens`; `~/.config/hypr/monitors.lua` is derived by running `omarchy-monitor-layout <name>`. Octi keeps its monitor file local.
- `install-mise-profile.sh` persists `MISE_ENV=$(hostname -s)` for the mise history watcher so host variants remain active after reboot.
- `~/.config/hypr/input.lua` is a regular file tracked and synchronized by mise through the private `dotfiles-private` history repository.
- Mise also owns `~/.bashrc`; `install-dotfiles.sh` no longer edits it after Stow runs.
- Omarchy's `~/.config/hypr/hyprland.lua` loads these modules with `require("hypr.monitors")`, `require("hypr.input")`, `require("hypr.bindings")`, and `require("hypr.looknfeel")`.
- If a legacy `~/.config/hypr/hyprland.conf` exists, the installer moves it aside so Hyprland uses the Lua config.
- `hyprland-base.conf` and `hyprland-looknfeel-compat.conf` are legacy references for the old `.conf` setup.

## DisplayLink Resume Recovery Notes

- Keep Omarchy's generic `hl.monitor({ output = "", mode = "preferred", position = "auto", ... })` rule enabled so Hyprland can auto-discover DisplayLink outputs after hotplug or resume.
- Do not pin `AQ_DRM_DEVICES` in Hyprland config. On this laptop it made reboot behavior worse and could leave displays unavailable.
- `recovery/install-displaylink-recover.sh` restarts `displaylink.service`, triggers DRM hotplug change events, reloads Hyprland, and replays monitor rules.
- If recovery reports `Failed to update renderer state for /dev/dri/card0`, Hyprland/Aquamarine saw the DisplayLink connector but failed renderer setup. In that state monitor rules are not enough; save work and restart Hyprland.
