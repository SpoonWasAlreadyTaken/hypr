import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
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

    property int volumeLevel: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) : 0
    function volumeIcon (muted, volume) { return muted ? "" : (volume >= 50 ? "" : (volume > 0 ? "" : "")) }

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

    property var audioStreams: []
    function setVolume(id, value) {
        Quickshell.execDetached(["wpctl", "set-volume", id.toString(), value.toString()])
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
        id: windowProcess
        command: ["sh", "-c", "hyprctl activewindow -j | jq -r '.class'"]
        stdout: SplitParser {
            onRead: data => {
                activeWindow = data.trim()

            }
        }

        Component.onCompleted: running = true
    }

    Process {
        id: audioService
        command: ["pactl", "list", "sink-inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                let result = []

                let blocks = text.split("\n\n")

                for (let block of blocks) {

                    let idMatch = block.match(/object\.id = "(\d+)"/)
                    if (!idMatch)
                    continue

                    let nameMatch = block.match(/media\.name = "(.+)"/)

                    let volumeMatch = block.match(/Volume:.*?(\d+)%/)

                    result.push({
                        id: Number(idMatch[1]),
                        name: nameMatch ? nameMatch[1] : "Unknown",
                        volume: volumeMatch ? Number(volumeMatch[1]) / 100 : 0
                    })
                }

                audioStreams = result

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
            networkProcess.running = true
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Timer {
        id: audioTimer
        interval: 1000
        repeat: true
        running: audioWindow.visible

        onTriggered: {
            if (!audioService.running) audioService.running = true
        }
    }

    Connections {
        target: Hyprland 

        function onRawEvent(event) { 
            if (event.name === "activewindow") {
                if (!windowProcess.running) windowProcess.running = true
            }
        }
    }

    
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
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
                        text: cpuUsage + "%"
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                        Layout.alignment: Qt.AlignBaseline
                    } 

                    Text { /* ICON */
                        text: ""
                        color: root.colorFGL
                        font { family: root.fontIcon; pixelSize: root.fontSize; bold: true }
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
                        text: memUsage + "%"
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    }

                    Text { /* ICON */
                        text: ""
                        color: root.colorFGL
                        font { family: root.fontIcon; pixelSize: root.fontSize; bold: true }
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
                        text: gpuUsage + "%"
                        color: root.colorFGL
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    } 

                    Text { /* ICON */
                        text: "󰩪"
                        color: root.colorFGL
                        font { family: root.fontIcon; pixelSize: root.fontSize; bold: true }
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

                    Item {
                        implicitWidth: audioRow.implicitWidth
                        implicitHeight: audioRow.implicitHeight

                        RowLayout {
                            id: audioRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text { /* AUDIO */
                                text: volumeLevel + "%"
                                color: root.colorFGL
                                font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                            }

                            Text { /* ICON */
                                text: volumeIcon(Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : 0, volumeLevel)
                                color: root.colorFGL
                                font { family: root.fontIcon; pixelSize: root.fontSize; bold: true } 
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { audioWindow.visible = !audioWindow.visible }
                            onWheel: (event) => {
                                Pipewire.defaultAudioSink.audio.volume += event.angleDelta.y > 0 ? (Pipewire.defaultAudioSink.audio.volume < 0.99 ? 0.01 : 0) : -0.01
                            }
                        }

                        Rectangle {
                            visible: audioWindow.visible
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            
                            width: parent.width * 1.2
                            height: 2
                            radius: 2
                            color: colorDark
                        }
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

    PanelWindow { /* FOCUS REMOVER */
        id: focusRemover
        visible: audioWindow.visible

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: { audioWindow.visible = false }
        }
    }

    // popup windows

    PanelWindow { /* AUDIO PANEL */
        id: audioWindow
        visible: false
        focusable: true

        implicitWidth: 600
        implicitHeight: 300

        anchors.top: true
        anchors.right: true

        color: "transparent"

        Shortcut {
            sequence: "Escape"
            onActivated: { audioWindow.visible = false }
        }

        Rectangle {
            anchors.fill: parent
            radius: 11
            anchors.margins: 4

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: colorFG
                }
                GradientStop {
                    position: 1.0
                    color: colorTertiary
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 10
            anchors.margins: 5

            color: colorDark

            Flickable {
                anchors.fill: parent
                anchors.margins: 20
                contentHeight: streamColumn.height + 15
                clip: true

                Column {
                    id: streamColumn
                    width: parent.width
                    spacing: 15


                    Repeater { 
                        model: audioStreams

                        delegate: Item {
                            id: slider



                            property real value: modelData.volume
                            property int streamId: modelData.id
                            width: parent.width * 0.85
                            height: 40

                            Column {
                                spacing: 8

                                Text {
                                    text: modelData.name
                                    color: colorFGL
                                    font { family: root.fontFamily; pixelSize: 14; bold: true }
                                    width: slider.width
                                    elide: Text.ElideRight
                                }

                                RowLayout {

                                    Item {
                                        width: slider.width
                                        height: 6

                                        Rectangle {
                                            id: track
                                            width: slider.width
                                            height: 6
                                            radius: 3
                                            color: colorBG

                                            Rectangle {
                                                width: track.width * slider.value
                                                height: parent.height
                                                radius: parent.radius
                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop {
                                                        position: 0.0
                                                        color: colorSecondary
                                                    }
                                                    GradientStop {
                                                        position: 1.0
                                                        color: colorTertiary
                                                    }
                                                }

                                            }
                                        }

                                        Rectangle {
                                            id: handle
                                            width: 14
                                            height: 14
                                            radius: 7
                                            color: colorBG
                                            border.width: 2
                                            border.color: colorTertiary
                                            x: (slider.value * (parent.width - width))
                                            y: (parent.height - height) / 2
                                        }

                                        MouseArea {
                                            anchors.centerIn: parent

                                            width: parent.width
                                            height: parent.height * 2

                                            preventStealing: true

                                            onPressed: (mouse) => { updateValue(mouse.x); audioTimer.running = false; }
                                            onReleased: (mouse) => { audioTimer.running = audioWindow.visible }
                                            onPositionChanged: (mouse) => { if (pressed) updateValue(mouse.x) }

                                            onWheel: (event) => {
                                                slider.value = Math.max(0, Math.min(1, slider.value + (event.angleDelta.y > 0 ? 0.01 : -0.01)))
                                                setVolume(slider.streamId, slider.value)
                                            }

                                            function updateValue(x) { 
                                                slider.value = Math.max(0, Math.min(1, x / slider.width))
                                                slider.value = Math.round(slider.value * 100) / 100
                                                rateLimiter.restart()
                                            }
                                        }

                                        Timer {
                                            id: rateLimiter

                                            interval: 50
                                            repeat: false

                                            onTriggered: {
                                                setVolume(slider.streamId, slider.value)
                                            }
                                        }
                                    }

                                    Text {
                                        text: Math.round(slider.value * 100) + "%"
                                        color: colorFGL
                                        font { family: root.fontFamily; pixelSize: 14; bold: true }
                                        Layout.preferredWidth: 50
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Text {
                                        text: volumeIcon(false, slider.value * 100)
                                        color: root.colorFGL
                                        font { family: root.fontIcon; pixelSize: 14; bold: true } 
                                        Layout.preferredWidth: 15
                                    }
                                }

                            }
                        }
                    }


                }

            }


        }
    }


}

