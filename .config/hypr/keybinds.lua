local mod = "SUPER"
local ipc = "noctalia msg"

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + Space",  hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))
hl.bind(mod .. " + W",      hl.dsp.exec_cmd("quickshell ipc call wallpaper toggle"))

-- Window management
hl.bind(mod .. " + Q",       hl.dsp.window.close())
hl.bind(mod .. " + V",       hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F",       hl.dsp.window.fullscreen())
hl.bind(mod .. " + P",       hl.dsp.window.pseudo())
hl.bind(mod .. " + J",       hl.dsp.layout("togglesplit"))

-- Focus
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down"  }))

-- Fenster verschieben
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left"  }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up"    }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down"  }))

-- Workspaces 1-9
for i = 1, 9 do
    hl.bind(mod .. " + " .. i,              hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i,      hl.dsp.window.move({ workspace = i }))
    hl.bind("CTRL + " .. mod .. " + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mod .. " + S",               hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S",       hl.dsp.window.move({ workspace = "special:magic" }))

-- Music Scratchpad
hl.bind("CTRL + " .. mod .. " + S",         hl.dsp.workspace.toggle_special("music"))
hl.bind("CTRL + " .. mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:music" }))

-- Scroll durch Workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Maus: bewegen & resizen
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshot
hl.bind("Print",           hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("grim - | wl-copy"))

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true })

-- Media
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
