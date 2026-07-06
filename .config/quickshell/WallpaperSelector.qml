import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "colors.js" as C

Item {
    id: root
    signal wallpaperApplied()

    readonly property string wallpaperDir: "/home/user/Pictures"
    property string currentPath: ""
    property var wallpapers: []

    function refresh() {
        listProc.running = true
        currentProc.running = true
    }

    Process {
        id: listProc
        command: ["sh", "-c", "ls -1 " + root.wallpaperDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n").filter(function (l) {
                    return /\.(png|jpe?g)$/i.test(l)
                })
                root.wallpapers = lines.map(function (l) {
                    return { name: l, path: root.wallpaperDir + "/" + l }
                })
            }
        }
    }

    Process {
        id: currentProc
        command: ["cat", "/home/user/.config/hypr/wallpaper.conf"]
        stdout: StdioCollector {
            onStreamFinished: root.currentPath = this.text.trim()
        }
    }

    Process { id: applyProc }
    Process { id: writeConfProc }

    function selectWallpaper(path) {
        var safe = path.replace(/'/g, "'\\''")
        applyProc.command = ["sh", "-c", "awww img '" + safe + "' --transition-type fade"]
        applyProc.running = true

        writeConfProc.command = ["sh", "-c", "printf '%s\\n' '" + safe + "' > ~/.config/hypr/wallpaper.conf"]
        writeConfProc.running = true

        root.currentPath = path
        root.wallpaperApplied()
    }

    Component.onCompleted: refresh()
    onVisibleChanged: if (visible) refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        Text {
            font.family: "Noto Sans"
            text: "Wallpaper"
            color: C.text
            font.pixelSize: 20
            font.weight: Font.Bold
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: C.border }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            // Cell aspect matches the actual monitor ratio (3840x1080 ultrawide) our
            // wallpapers are authored for, not 16:9 — otherwise PreserveAspectCrop
            // zooms into the center third of every ultrawide wallpaper.
            cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 500)))
            cellHeight: cellWidth * 1080 / 3840 + 14
            model: root.wallpapers
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Item {
                id: cell
                required property var modelData
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 7
                    radius: 12
                    color: C.surface
                    clip: true
                    border.width: modelData.path === root.currentPath ? 3 : (thumbMa.containsMouse ? 1 : 0)
                    border.color: modelData.path === root.currentPath ? C.accent : C.border

                    Image {
                        anchors.fill: parent
                        source: "file://" + modelData.path
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        cache: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: C.accent
                        opacity: thumbMa.containsMouse && modelData.path !== root.currentPath ? 0.12 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: thumbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectWallpaper(cell.modelData.path)
                    }
                }
            }

            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                anchors.centerIn: parent
                visible: grid.count === 0
                text: "Keine Wallpaper gefunden"
                color: C.textMuted
                font.pixelSize: 13
            }
        }
    }
}
