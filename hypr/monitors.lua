-- omarchy-supplement monitor setup for Omarchy Quattro / Hyprland Lua config.
-- List current monitors and modes with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.5

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Keep Omarchy's generic auto rule so DisplayLink/hotplug outputs are discovered.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

hl.monitor({
	output = "eDP-1",
	mode = "1920x1200@59.95",
	position = "4448x550",
	scale = 1.5,
})
hl.monitor({
	output = "DVI-I-1",
	mode = "3840x2160@60.0",
	position = "2048x0",
	scale = 1.6,
})

-- Stationary setup.
-- hl.monitor({ output = "desc:Dell Inc. DELL U2717D", mode = "2560x1440@59.95", position = "0x0", scale = 1.25 })
-- hl.monitor({ output = "desc:LG Electronics LG ULTRAGEAR", disabled = true })

-- Workspace placement. These are non-persistent: empty workspaces stay hidden.
for workspace = 1, 7 do
	hl.workspace_rule({ workspace = tostring(workspace), monitor = "DVI-I-1" })
end

hl.workspace_rule({ workspace = "8", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1" })
-- hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })

-- Stationary workspace assignments.
-- for workspace = 1, 10 do
--   hl.workspace_rule({ workspace = tostring(workspace), monitor = "desc:Dell Inc. DELL P3225DE BXSHC34" })
-- end
