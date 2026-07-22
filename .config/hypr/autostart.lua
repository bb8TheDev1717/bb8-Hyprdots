hl.on("hyprland.start", function()
    -- Audio: no systemd here (OpenRC/elogind), so pipewire never gets
    -- socket/service-activated on its own -- start it explicitly.
    hl.exec_cmd("pipewire")
    hl.exec_cmd("pipewire-pulse")
    hl.exec_cmd("wireplumber")

    -- Wallpaper first, before anything else competes for startup time
    -- (awww-daemon restores the cached last image on its own; this is
    -- only a fallback for a cleared cache, polled instead of a fixed
    -- sleep so it fires as soon as the daemon socket is up)
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("for i in $(seq 1 40); do awww query >/dev/null 2>&1 && break; sleep 0.05; done; " ..
        "awww query 2>/dev/null | grep -q 'image:' || " ..
        "awww img \"$(cat ~/.config/hypr/wallpaper.conf)\" --transition-type none")

    hl.exec_cmd("quickshell")
    hl.exec_cmd("python3 ~/.config/hypr/scripts/ws-tracker.py &")
    hl.exec_cmd("xhost +local:")
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")
    hl.exec_cmd("hyprctl setcursor Sweet-cursors 24")
    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- Portals (screenshare, links)
    hl.exec_cmd("sleep 2 && /usr/lib/xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 4 && /usr/lib/xdg-desktop-portal")
end)
