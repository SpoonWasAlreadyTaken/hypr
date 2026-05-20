local G = require('modules.globals')

hl.on("hyprland.start", function ()
    hl.exec_cmd(G.terminal)
    hl.exec_cmd('swaync')
    hl.exec_cmd('waybar')
end)
