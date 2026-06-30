-- omarchy-supplement keybinding overrides.
-- See active bindings with: omarchy menu keybindings --print

local omarchy_shell_env = "omarchy-shell"

-- Unbind conflicting defaults before remapping.
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + CTRL + H")

hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")
hl.unbind("SUPER + ALT + LEFT")
hl.unbind("SUPER + ALT + RIGHT")
hl.unbind("SUPER + ALT + UP")
hl.unbind("SUPER + ALT + DOWN")
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")
hl.unbind("SUPER + SHIFT + ALT + LEFT")
hl.unbind("SUPER + SHIFT + ALT + RIGHT")

-- Vim-style navigation with hjkl.
o.bind("SUPER + H", "Move window focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Move window focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Move window focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Move window focus right", hl.dsp.focus({ direction = "r" }))

o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

o.bind("SUPER + ALT + H", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + ALT + J", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))
o.bind("SUPER + ALT + K", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + ALT + L", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))

o.bind("SUPER + CTRL + H", "Move grouped window focus left", hl.dsp.group.prev())
o.bind("SUPER + CTRL + L", "Move grouped window focus right", hl.dsp.group.next())

o.bind("SUPER + SHIFT + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))

-- Remapped utilities due to hjkl conflicts.
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
hl.unbind("SUPER + ESCAPE")
o.bind("SUPER + U", "Show key bindings", "omarchy-menu-keybindings")
o.bind("SUPER + I", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SPACE", "Launch apps", omarchy_shell_env .. " shell toggle omarchy.launcher '{}'")
o.bind("SUPER + ALT + SPACE", "Omarchy menu", "omarchy-menu toggle root")
o.bind("SUPER + ESCAPE", "System menu", "omarchy-menu toggle system")

-- Override lock screen binding.
o.bind("SUPER + CTRL + ESCAPE", "Lock system", "omarchy system lock")
