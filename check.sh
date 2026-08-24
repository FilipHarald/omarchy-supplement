#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
PLUGIN_ID="local.current-screen-workspaces"
PLUGIN_SOURCE="$SCRIPT_DIR/shell-plugins/current-screen-workspaces"
PLUGIN_TARGET="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SHELL_CONFIG="$HOME/.config/omarchy/shell.json"
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
for file in input.lua bindings.lua looknfeel.lua; do
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

host_name="$(hostname -s)"
if [ "$host_name" = "decem" ] && [ -f "$SCRIPT_DIR/hypr/monitors.lua" ] && \
   [ -f "$HOME/.config/hypr/monitors.lua" ] && \
   cmp -s "$SCRIPT_DIR/hypr/monitors.lua" "$HOME/.config/hypr/monitors.lua"; then
  pass "decem-specific monitors.lua matches the live file"
elif [ "$host_name" = "decem" ]; then
  fail "decem-specific monitors.lua is missing or differs from the live file"
elif [ -f "$SCRIPT_DIR/hypr/monitors.lua" ]; then
  pass "decem-specific monitors.lua is checked in and skipped on host $host_name"
else
  fail "decem-specific monitors.lua is missing from the supplement"
fi

if omarchy-plugin-validate "$PLUGIN_SOURCE" >/dev/null 2>&1; then
  pass "workspace plugin source validates"
else
  fail "workspace plugin source does not validate"
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
