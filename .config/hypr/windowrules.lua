-- ─── Window Rules ────────────────────────────────────────────────────────────
hl.window_rule({
    name  = "music-scratchpad",
    match = { class = "^FFPWA-01KSVX4YRM3KMFS40W2S4J1N0K$" },
    workspace = "special:music",
    float = true,
})

hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true,
})
hl.window_rule({
    name  = "float-blueman",
    match = { class = "^(blueman-manager)$" },
    float = true,
})
hl.window_rule({
    name  = "float-nm",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})
