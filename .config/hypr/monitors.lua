-- HP E273q 27" (links, gerade, 1080p für Alignment)
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

-- ASUS XG49V 49" Ultrawide (Haupt-Monitor, rechts)
hl.monitor({
    output   = "DP-1",
    mode     = "3840x1080@143.85",
    position = "1920x0",
    scale    = 1,
})

-- Workspaces 1-9 auf DP-1 (Ultrawide, Haupt-Monitor)
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1" })
end

-- Workspace 11 fest auf HDMI-A-1 als einziger Workspace dort
hl.workspace_rule({ workspace = "11", monitor = "HDMI-A-1", default = true })
