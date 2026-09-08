#!/bin/bash

set -uo pipefail

export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
PLUGIN_ID="local.current-screen-workspaces"
PLUGIN_SOURCE="$SCRIPT_DIR/shell-plugins/current-screen-workspaces"
PLUGIN_TARGET="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SHELL_CONFIG="$HOME/.config/omarchy/shell.json"
MISE_BIN="$(command -v mise)"
if [ -x "$HOME/.local/bin/mise" ]; then
  MISE_BIN="$HOME/.local/bin/mise"
fi
passes=0
warnings=0
failures=0

pass() { printf 'PASS  %s\n' "$*"; passes=$((passes + 1)); }
warn() { printf 'WARN  %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }

check_repo() {
  local label="$1" repo="$2" counts
  if [ ! -d "$repo/.git" ]; then
    fail "$label repository is missing: $repo"
    return
  fi

  if git -C "$repo" diff --quiet && git -C "$repo" diff --cached --quiet; then
    pass "$label worktree is clean"
  else
    warn "$label worktree has tracked changes"
    git -C "$repo" status --short
  fi

  if git -C "$repo" rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
    counts="$(git -C "$repo" rev-list --left-right --count 'HEAD...@{upstream}')"
    if [ "$counts" = $'0\t0' ]; then
      pass "$label matches its locally known upstream"
    else
      warn "$label differs from its locally known upstream (ahead/behind: $counts)"
    fi
  else
    warn "$label has no upstream branch configured"
  fi
}

echo "Omarchy supplement check"
echo "========================"

for command in git stow omarchy jq nvim omarchy-plugin-validate; do
  if command -v "$command" >/dev/null 2>&1; then
    pass "$command is available"
  else
    fail "$command is not available"
  fi
done

check_repo "dotfiles" "$DOTFILES"
check_repo "supplement" "$SCRIPT_DIR"

if [ -d "$DOTFILES" ]; then
  stow_failed=0
  for package_dir in "$DOTFILES"/*/; do
    package="$(basename "$package_dir")"
    [ "$package" = "legacy" ] && continue
    if ! stow -nRv --no-folding --target="$HOME" --dir="$DOTFILES" "$package" >/dev/null 2>&1; then
      fail "Stow dry-run found a conflict in $package"
      stow_failed=1
    fi
  done
  [ "$stow_failed" -eq 0 ] && pass "all dotfile packages pass a no-folding Stow dry-run"

  secret_path="opencode/.config/opencode/opencode-secrets.sh"
  if ! git -C "$DOTFILES" ls-files --error-unmatch "$secret_path" >/dev/null 2>&1 && \
     { [ ! -e "$DOTFILES/$secret_path" ] || git -C "$DOTFILES" check-ignore -q "$secret_path"; }; then
    pass "OpenCode secrets file is absent or safely ignored, and is untracked"
  else
    fail "OpenCode secrets file is not safely ignored and untracked"
  fi

  if [ ! -e "$DOTFILES/soljson-latest.js" ] && \
     { ! git -C "$DOTFILES" ls-files --error-unmatch soljson-latest.js >/dev/null 2>&1 || \
       ! git -C "$DOTFILES" diff --quiet --diff-filter=D -- soljson-latest.js; }; then
    pass "soljson-latest.js is absent"
  else
    fail "soljson-latest.js is still present or tracked"
  fi

  aw_config="$DOTFILES/activitywatch/.config/activitywatch/aw-tauri/config.toml"
  if [ -f "$aw_config" ] && ! grep -q '/home/filip' "$aw_config" && grep -Eq '^discovery_paths[[:space:]]*=[[:space:]]*\[\]' "$aw_config"; then
    pass "ActivityWatch uses portable default discovery paths"
  else
    fail "ActivityWatch config is not portable"
  fi
fi

hypr_drift=0
for file in bindings.lua looknfeel.lua; do
  if [ ! -f "$SCRIPT_DIR/hypr/$file" ]; then
    fail "portable Hyprland source is missing: $file"
    hypr_drift=1
  elif [ ! -f "$HOME/.config/hypr/$file" ]; then
    warn "live Hyprland config is missing: $file"
    hypr_drift=1
  elif ! cmp -s "$SCRIPT_DIR/hypr/$file" "$HOME/.config/hypr/$file"; then
    warn "live Hyprland config differs: $file"
    hypr_drift=1
  fi
done
[ "$hypr_drift" -eq 0 ] && pass "portable Hyprland config matches the live files"

if "$MISE_BIN" bootstrap dotfiles paths 2>/dev/null | grep -Fq '~/.config/hypr/input.lua'; then
  pass "Hyprland input.lua is tracked by mise"
else
  fail "Hyprland input.lua is not tracked by mise"
fi

host_name="$(hostname -s)"
mise_service_environment="$(systemctl --user show dev.mise.mise-history.service -p Environment --value 2>/dev/null || true)"
if grep -Eq "(^|[[:space:]])MISE_ENV=$host_name([[:space:]]|$)" <<< "$mise_service_environment"; then
  pass "mise history watcher uses the $host_name profile"
else
  fail "mise history watcher is not configured with MISE_ENV=$host_name"
fi

if [ "$host_name" = "decem" ]; then
  mise_paths="$("$MISE_BIN" -E decem bootstrap dotfiles paths 2>/dev/null)"
  if grep -Fq '~/.config/hypr/monitor-layouts/one-screen.lua' <<< "$mise_paths" && \
     grep -Fq '~/.config/hypr/monitor-layouts/two-screens.lua' <<< "$mise_paths" && \
     grep -Fq '~/.local/bin/omarchy-monitor-layout' <<< "$mise_paths"; then
    pass "decem monitor layouts and switcher are tracked by the decem mise profile"
  else
    fail "decem monitor layouts or switcher are not tracked by the decem mise profile"
  fi

  if grep -Fq '~/.config/hypr/monitors.lua' <<< "$mise_paths"; then
    fail "derived monitors.lua is still tracked by mise"
  elif cmp -s "$HOME/.config/hypr/monitors.lua" "$HOME/.config/hypr/monitor-layouts/one-screen.lua" || \
       cmp -s "$HOME/.config/hypr/monitors.lua" "$HOME/.config/hypr/monitor-layouts/two-screens.lua"; then
    pass "active monitors.lua matches a named layout"
  else
    fail "active monitors.lua does not match a named layout"
  fi
else
  pass "monitors.lua remains host-local on $host_name"
fi

if omarchy-plugin-validate "$PLUGIN_SOURCE" >/dev/null 2>&1; then
  pass "workspace plugin source validates"
else
  fail "workspace plugin source does not validate"
fi

OMACOACH_ID="io.github.filipharald.omacoach"
OMACOACH_DIR="$HOME/.config/omarchy/plugins/$OMACOACH_ID"
OMACOACH_SOURCE="$(readlink -f "$OMACOACH_DIR" 2>/dev/null || true)"
if [ -n "$OMACOACH_SOURCE" ] && [ -d "$OMACOACH_SOURCE/.git" ] && \
   omarchy-plugin-validate "$OMACOACH_SOURCE" >/dev/null 2>&1; then
  pass "Omacoach is installed and validates"
else
  fail "Omacoach is missing or invalid"
fi

if omarchy plugin list 2>/dev/null | grep -Eq "^$OMACOACH_ID[[:space:]]+enabled"; then
  pass "Omacoach is enabled"
else
  fail "Omacoach is not enabled"
fi

if grep -Fq -- '-- omacoach:start' "$HOME/.config/hypr/bindings.lua" && \
   grep -Fq -- '-- omacoach-binding:start' "$HOME/.config/hypr/bindings.lua"; then
  pass "Omacoach observer and panel binding are installed"
else
  fail "Omacoach bindings are missing"
fi

if [ -d "$PLUGIN_TARGET" ] && diff -qr "$PLUGIN_SOURCE" "$PLUGIN_TARGET" >/dev/null 2>&1; then
  pass "workspace plugin source matches the live plugin"
else
  warn "workspace plugin source differs from the live plugin"
fi

if [ -f "$SHELL_CONFIG" ] && jq -e --arg id "$PLUGIN_ID" \
  '[.bar.layout[][]? | select(type == "object") | .id] | index($id) != null' \
  "$SHELL_CONFIG" >/dev/null 2>&1; then
  pass "shell.json is valid and uses the workspace plugin"
else
  fail "shell.json is invalid or does not use the workspace plugin"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl instances 2>/dev/null | grep -q '^instance '; then
  hyprctl_args=()
  [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && hyprctl_args=(-i 0)
  errors="$(hyprctl "${hyprctl_args[@]}" configerrors 2>/dev/null || true)"
  if [ -z "$errors" ]; then
    pass "Hyprland reports no configuration errors"
  else
    fail "Hyprland configuration errors: $errors"
  fi
else
  warn "Hyprland is not running; live config errors were not checked"
fi

echo
printf 'Summary: %d passed, %d warnings, %d failed\n' "$passes" "$warnings" "$failures"
[ "$failures" -eq 0 ]
