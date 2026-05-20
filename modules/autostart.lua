

hl.on("hyprland.start", function ()
    hl.exec_cmd(terminal)
    hl.exec_cmd('swaync')
    hl.exec_cmd('waybar')
end)
