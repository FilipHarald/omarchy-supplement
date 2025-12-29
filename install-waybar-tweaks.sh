#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
BACKUP_CONFIG="$WAYBAR_CONFIG.bak"
BACKUP_STYLE="$WAYBAR_STYLE.bak"

# Check if waybar config exists
if [ ! -f "$WAYBAR_CONFIG" ]; then
    echo "Waybar config not found at $WAYBAR_CONFIG"
    echo "Please install Omarchy/waybar first"
    exit 1
fi

# Create backups if they don't exist
if [ ! -f "$BACKUP_CONFIG" ]; then
    echo "Creating backup of waybar config..."
    cp "$WAYBAR_CONFIG" "$BACKUP_CONFIG"
fi

if [ -f "$WAYBAR_STYLE" ] && [ ! -f "$BACKUP_STYLE" ]; then
    echo "Creating backup of waybar style..."
    cp "$WAYBAR_STYLE" "$BACKUP_STYLE"
fi

echo "Applying waybar configuration tweaks..."

# Always show tray (not in expander)
echo "- Removing tray expander..."
sed -i '/"group\/tray-expander": {/,/^  },$/d' "$WAYBAR_CONFIG"
sed -i '/"custom\/expand-icon": {/,/^  },$/d' "$WAYBAR_CONFIG"
sed -i 's/"group\/tray-expander"/"tray"/' "$WAYBAR_CONFIG"

# Remove persistent-workspaces to allow dynamic workspace detection
echo "- Removing persistent-workspaces for dynamic detection..."
sed -i '/"persistent-workspaces": {/,/^    }/d' "$WAYBAR_CONFIG"

# Add all-outputs: false if not present
if ! grep -q '"all-outputs"' "$WAYBAR_CONFIG"; then
    echo "- Setting all-outputs to false..."
    sed -i '/"hyprland\/workspaces": {/a\    "all-outputs": false,' "$WAYBAR_CONFIG"
fi

# Change workspace format to show numbers instead of icons
echo "- Updating workspace format to show numbers..."
sed -i '/"hyprland\/workspaces": {/,/^  },$/s/"format": "{icon}"/"format": "{name}"/' "$WAYBAR_CONFIG"

# Add CSS overrides by importing our override file
echo "Adding CSS style overrides..."
if [ -f "$WAYBAR_STYLE" ]; then
    # Check if our import already exists
    if ! grep -q "omarchy-supplement/waybar-style-overrides.css" "$WAYBAR_STYLE"; then
        # Add import at the end of the file
        echo "" >> "$WAYBAR_STYLE"
        echo "/* Omarchy supplement overrides */" >> "$WAYBAR_STYLE"
        echo "@import \"$SCRIPT_DIR/waybar-style-overrides.css\";" >> "$WAYBAR_STYLE"
    fi
fi

echo "Waybar tweaks applied successfully!"
echo "Restarting waybar..."

# Kill and restart waybar
killall waybar 2>/dev/null || true
sleep 1
waybar &>/dev/null &

echo ""
echo "✓ Waybar configured with:"
echo "  - Always visible tray icons"
echo "  - Workspace numbers (not icons)"
echo "  - Active workspace highlighted in accent color"
echo "  - Dynamic workspace detection (no hardcoded outputs)"
