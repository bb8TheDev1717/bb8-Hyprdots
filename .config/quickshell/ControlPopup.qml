import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "colors.js" as C

Item {
    id: root
    signal requestClose()

    property string wallpaperPath: ""
    property string hostname: ""
    Process {
        running: true
        command: ["cat", "/home/user/.config/hypr/wallpaper.conf"]
        stdout: StdioCollector {
            onStreamFinished: root.wallpaperPath = this.text.trim()
        }
    }
    Process {
        running: true
        command: ["hostname"]
        stdout: StdioCollector {
            onStreamFinished: root.hostname = this.text.trim()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Hero: wallpaper filling the whole free area, with "Hallo!" +
        // hostname overlaid at the bottom (scrim behind for legibility).
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: C.surface
            clip: true
            border.width: 1
            border.color: C.border

            Image {
                anchors.fill: parent
                source: root.wallpaperPath.length > 0 ? "file://" + root.wallpaperPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    openWallpaperProc.running = true
                    root.requestClose()
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.55
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.65) }
                }
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 14
                spacing: 2
                Text {
                    font.family: "Noto Sans"
                    text: "Hallo!"
                    color: "white"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
                Text {
                    font.family: "Noto Sans"
                    font.weight: Font.DemiBold
                    text: root.hostname
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.pixelSize: 12
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: C.border }

        // Power menu
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    { label: "Sperren",  cmd: ["loginctl", "lock-session"], col: C.textDim },
                    { label: "Neustart", cmd: ["systemctl", "reboot"],      col: C.green },
                    { label: "Aus",      cmd: ["systemctl", "poweroff"],    col: C.red }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 10
                    color: powMa.containsMouse ? C.surfaceHi : C.surface
                    Behavior on color { ColorAnimation { duration: 120 } }
                    border.width: powMa.containsMouse ? 1 : 0
                    border.color: modelData.col

                    Text {
                        font.family: "Noto Sans"
                        anchors.centerIn: parent
                        text: modelData.label
                        color: powMa.containsMouse ? modelData.col : C.textDim
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                    MouseArea {
                        id: powMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            powerProc.command = modelData.cmd
                            powerProc.running = true
                            root.requestClose()
                        }
                    }
                }
            }
        }
    }

    Process { id: powerProc }
    Process { id: openWallpaperProc; command: ["quickshell", "ipc", "call", "wallpaper", "open"] }
}
