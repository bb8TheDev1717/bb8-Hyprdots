-- ~/.config/hypr/hyprland.lua
-- My Hyprland Config

require("monitors")
require("env")
require("autostart")
require("keybinds")
require("windowrules")

-- ─── Input ───────────────────────────────────────────────────────────────────
hl.config({
    input = {
        kb_layout     = "de",
        kb_variant    = "",
        kb_model      = "",
        kb_options    = "",
        kb_rules      = "",
        follow_mouse  = 1,
        sensitivity   = 0,
        accel_profile = "flat",
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- ─── General ────────────────────────────────────────────────────────────────
hl.config({
    general = {
        gaps_in       = 5,
        gaps_out      = 10,
        border_size   = 1,
        col = {
            active_border   = "rgb(A78BFA)",
            inactive_border = "rgb(242436)",
        },
        layout        = "dwindle",
        allow_tearing = false,
    },
})

-- ─── Decoration — Shade Theme ────────────────────────────────────────────────
hl.config({
    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 0.95,
        inactive_opacity = 0.65,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            color          = "rgba(0, 0, 0, 0.9)",
            color_inactive = "rgba(0, 0, 0, 0.8)",
        },

        blur = {
            enabled   = false,
            size      = 10,
            passes    = 4,
            vibrancy  = 0.79,     -- 79% Blur-Vibranz
            new_optimizations = true,
        },
    },
})

-- ─── Animations ──────────────────────────────────────────────────────────────
hl.config({ animations = { enabled = true } })

hl.curve("ease",      { type = "bezier", points = { {0.25, 0.1}, {0.25, 1.0} } })
hl.curve("overshoot", { type = "bezier", points = { {0.05, 0.9}, {0.1,  1.05} } })
hl.curve("quick",     { type = "bezier", points = { {0.15, 0},   {0.1,  1}   } })
hl.curve("easy",      { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",     enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "windows",    enabled = true, speed = 5,   spring = "easy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4,   spring = "easy",  style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "quick", style = "popin 87%" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,   bezier = "ease" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4,   bezier = "quick" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3,   bezier = "ease",  style = "slide" })

-- ─── Layouts ─────────────────────────────────────────────────────────────────
hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
})

-- ─── Misc ────────────────────────────────────────────────────────────────────
hl.config({
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
    },
})
