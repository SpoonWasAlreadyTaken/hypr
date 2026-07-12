local G = require('modules.globals')



-- rules


hl.workspace_rule({
    workspace = "0",
    monitor = G.secondaryMonitor,
})
hl.workspace_rule({
    workspace = "1",
    monitor = G.secondaryMonitor,
    default = true,
})
hl.workspace_rule({
    workspace = "2",
    monitor = G.secondaryMonitor,
})
hl.workspace_rule({
    workspace = "3",
    monitor = G.mainMonitor,
    default = true,
})
hl.workspace_rule({
    workspace = "4",
    monitor = G.mainMonitor,
})
hl.workspace_rule({
    workspace = "5",
    monitor = G.mainMonitor,
})
hl.workspace_rule({
    workspace = "6",
    monitor = G.mainMonitor,
})
hl.workspace_rule({
    workspace = "7",
    monitor = G.mainMonitor,
})
hl.workspace_rule({
    workspace = "8",
    monitor = G.mainMonitor,
})
hl.workspace_rule({
    workspace = "9",
    monitor = G.mainMonitor,
})


hl.window_rule({
    name = "discord-1",
    match = { class = "^(vesktop)$" },
    workspace = "1 silent",
})

hl.window_rule({
    name = "terminal-2",
    match = { class = "^(com.mitchellh.ghostty)$" },
    workspace = "3 silent",
})

hl.window_rule({
    name = "firefox-workspace-3",
    match = { class = "^(firefox)$" },
    workspace = "4 silent",
})

hl.window_rule({
    name = "steam-5",
    match = { class = "^(steam)$" },
    workspace = "5 silent",
})

-- autostart
hl.on("hyprland.start", function ()
    hl.exec_cmd(G.terminal)
    hl.exec_cmd('swaync')
    hl.exec_cmd('quickshell -p ~/.config/hypr/quickshell')
    hl.exec_cmd('hyprpaper')
    hl.exec_cmd('firefox')
end)















