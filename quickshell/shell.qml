import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts




ShellRoot {
    id: root

    property color colorBG: "#040405"
    property color colorFG: "#f38ba8"
    property color colorFGL: "#f2a9be"
    property color colorDim: "#424242"
    property color colorPink: "#f24878"
    property color colorPinkDim: "#7f4858"
    property color colorPinkDark: "#3f242c"
    property color colorAccent: "#ff7c36"
    property color colorSecondary: "#938bb4"
    property color colorTertiary: "#ff005d"
    property color colorDark: "#16161c"

    property string fontFamily: "Cascadia Mono"
    property string fontIcon: "JetBrainsMono Nerd Font"
    property int fontSize: 17
    property int iconSize: 27


    // system vars
    property int cpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    property int gpuUsage: 0

    property int memUsage: 0

    property bool online: false

    property int volumeLevel: 0
    property string volumeIcon: volumeLevel > 50 ? " " : ( volumeLevel > 0 ? " " : " ")

    property string clock: Qt.formatDateTime(new Date(), "HH:mm")

    property string systemIcon: "󰣇"
    property string activeWindow: systemIcon
    function getIcon(activeWindow) {
        switch (activeWindow) {
            case "com.mitchellh.ghostty":
            return "󰊠"
            break
            case "firefox":
            return "󰈹"
            break
            case "steam":
            return ""
            break
            case "vesktop":
            return ""
            break
            default:
            return systemIcon
        }
    }


    Process {
        id: cpuProcess
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(/\s+/)
                var idle = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)

                if (lastCpuTotal > 0) {
                    cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
                }
                lastCpuTotal = total
                lastCpuIdle = idle
            }
        }

        Component.onCompleted: running = true
    }

    Process {
        id: gpuProcess
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                gpuUsage = parseInt(data.trim()) || 0
            }
        }

        Component.onCompleted: running = true
    }

    Process {
        id: memProcess
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }

        Component.onCompleted: running = true
    }

    Process {
        id: networkProcess
        command: ["sh", "-c", "ping -c 1 -W 1 1.1.1.1 >/dev/null 2>&1 && echo online || echo offline"]
        stdout: SplitParser {
            onRead: data => {
                online = data.trim() === "online"
            }
        }

        Component.onCompleted: running = true
    }


    Process {
        id: audioProcess
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var match = data.match(/Volume:\s*([\d.]+)/)
                if (match) { volumeLevel = Math.round(parseFloat(match[1]) * 100) }
            }
        }

        Component.onCompleted: running = true
    }

    Process {
        id: windowProcess
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.class'"]
        stdout: SplitParser {
            onRead: data => {
                activeWindow = data.trim()

            }
        }

        Component.onCompleted: running = true
    }




    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: { 
            cpuProcess.running = true 
            memProcess.running = true 
            gpuProcess.running = true 
            audioProcess.running = true
            networkProcess.running = true
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Connections {
        target: Hyprland 

        function onRawEvent(event) { 
            if (event.name === "activewindow") {
                if (!windowProcess.running) windowProcess.running = true
            }
        }
    }

    Variants {
        model: Quickshell.screens

        // actual bar
        PanelWindow {
            property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true
            implicitHeight: 32
            color: colorBG


            Item {
                anchors.fill: parent
                anchors.verticalCenter: parent.verticalCenter

                RowLayout { /* LEFT */
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    anchors.leftMargin: 12

                    Text { /* CPU */
                        text: cpuUsage + "%" + " "
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                        Layout.alignment: Qt.AlignBaseline
                    } 

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colorDark
                    }

                    Text { /* MEMORY */
                        text: memUsage + "%" + " "
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colorDark
                    }

                    Text { /* GPU */
                        text: gpuUsage + "%" + " 󰩪"
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    }
                }


                RowLayout { /* CENTER */
                    anchors.centerIn: parent
                    Layout.alignment: Qt.AlignHCenter

                    spacing: 8

                    RowLayout {           
                        Repeater {
                            model: 5

                            Text { /* WORKSPACES 1-5 */
                                property int wsID: index + 1
                                property var ws: Hyprland.workspaces.values.find(w => w.id === wsID)
                                property bool isActive: Hyprland.focusedWorkspace?.id === (wsID)

                                text: isActive ? "" : ""
                                color: isActive ? colorFG : (ws ? colorPinkDim : colorDim)
                                font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (wsID) + "})")
                                }
                            }
                        }
                    }

                    Item {
                        width: 30
                        height: parent.height

                        Text { /* ACTIVE WINDOW */
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            rightPadding: activeWindow === "vesktop" ? 10 : (activeWindow === "com.mitchellh.ghostty" ? 0 : 5)

                            text: getIcon(activeWindow)
                            color: colorFG
                            font { family: root.fontIcon; pixelSize: root.iconSize; bold: true }
                        }
                    }

                    RowLayout {
                        Repeater {
                            model: 5

                            Text { /* WORKSPACES 6-10 */
                                property int wsID: 5 + index + 1
                                property var ws: Hyprland.workspaces.values.find(w => w.id === wsID)
                                property bool isActive: Hyprland.focusedWorkspace?.id === (wsID)

                                text: isActive ? "" : ""
                                color: isActive ? colorFG : (ws ? colorPinkDim : colorDim)
                                font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (wsID) + "})")
                                }
                            }
                        }
                    }
                }


                RowLayout { /* RIGHT */
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    anchors.rightMargin: 12

                    Text { /* NETWORK */
                        id: network
                        text: online ? "online" : "offline"
                        color: online ? root.colorFGL : root.colorDim
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colorDark
                    }

                    Text { /* AUDIO */
                        text: volumeLevel + "%" + root.volumeIcon
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    }

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        color: root.colorDark
                    }

                    Text { /* CLOCK */
                        text: clock
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    }
                }
            }
        }
    }
}

