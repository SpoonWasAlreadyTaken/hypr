local G = require('modules.globals')

hl.on("hyprland.start", function ()
    hl.exec_cmd(G.terminal)
    hl.exec_cmd('swaync')
    hl.exec_cmd('waybar')
end)






-- window rules 
--hl.window_rule({})



hl.window_rule({
    name = "firefox-workspace-3",
    match = { class = "^(firefox)$" },
    workspace = "3 silent",
})







