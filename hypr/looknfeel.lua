-- omarchy-supplement look-and-feel overrides.

-- Disable window open/close/move animations while leaving other Omarchy effects alone.
hl.animation({ leaf = "windowsIn", enabled = false })
hl.animation({ leaf = "windowsOut", enabled = false })
hl.animation({ leaf = "windowsMove", enabled = false })

hl.config({
  misc = {
    focus_on_activate = false,
  },
})
