#!/bin/bash

chosen=$(printf "Cancel\0icon\x1fdialog-cancel\nSleep\0icon\x1fsystem-suspend\nShutdown\0icon\x1fsystem-shutdown\nReboot\0icon\x1fsystem-reboot\nLogout\0icon\x1fsystem-log-out\n" | rofi -dmenu -i -p "Power" -show-icons)

[[ "$chosen" == "Cancel" ]] && exit 0

case "$chosen" in 
    *Sleep*)
        hyprlock & sleep 1
        systemctl suspend
        ;;
    *Shutdown*)
        hyprshutdown --post-cmd "systemctl poweroff"
        ;;
    *Reboot*)
        hyprshutdown --post-cmd "systemctl reboot"
        ;;
    *Logout*)
        hyprshutdown
        ;;
esac
