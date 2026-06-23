#!/bin/bash

chosen=$(printf "⏻ Shutdown\n󰜉 Reboot\n󰒲 Sleep\n󰍃 Logout\n󰜺 Cancel\n" | rofi -dmenu -i -p "Power")

[[ "$chosen" == "Cancel" ]] && exit 0

case "$chosen" in 
    *Shutdown*)
        hyprshutdown --post-cmd "systemctl poweroff"
        ;;
    *Reboot*)
        hyprshutdown --post-cmd "systemctl reboot"
        ;;
    *Sleep*)
        systemctl suspend
        ;;
    *Logout*)
        hyprshutdown
        ;;
esac
