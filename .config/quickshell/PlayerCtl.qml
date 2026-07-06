import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "colors.js" as C

Item {
    id: root

    property bool active: false   // set true by the page host while this tab is visible

    property string status: ""
    property string artist: ""
    property string title: ""
    property string artUrl: ""
    property real position: 0   // seconds
    property real length: 0     // seconds

    property var cavaBars: []

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

        Item { Layout.fillHeight: true }

        // Album art
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 150
            Layout.preferredHeight: 150
            radius: 16
            color: C.surface
            clip: true
            Image {
                id: albumImg
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl.length > 0 && albumImg.status === Image.Ready
                asynchronous: true
            }
            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                anchors.centerIn: parent
                text: "♪"
                color: C.textMuted
                font.pixelSize: 52
                visible: !albumImg.visible
            }
        }

        // Title + artist
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                font.family: "Noto Sans"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.title.length > 0 ? root.title : "Nichts spielt"
                color: C.text
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.artist
                color: C.textMuted
                font.pixelSize: 13
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        // Cava audio visualizer — fixed-height Item wrapping a plain Row
        // (not RowLayout!) so animated bar heights can never feed back into
        // the ColumnLayout's size calculation and shift the elements below.
        Item {
            id: cavaBox
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.minimumHeight: 40
            Layout.maximumHeight: 40
            clip: true

            Row {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height
                spacing: 3

                Repeater {
                    model: root.cavaBars
                    delegate: Rectangle {
                        required property real modelData
                        required property int index
                        width: root.cavaBars.length > 0
                               ? (cavaBox.width - (root.cavaBars.length - 1) * 3) / root.cavaBars.length
                               : 0
                        anchors.bottom: parent.bottom
                        height: Math.max(3, Math.min(40, modelData / 100 * 40))
                        radius: 2
                        color: C.accent
                        opacity: 0.55 + 0.45 * (modelData / 100)
                        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                    }
                }
            }
        }

        // Progress
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: C.surfaceHi
            Rectangle {
                height: parent.height
                radius: 2
                color: C.accent
                width: root.length > 0 ? parent.width * Math.min(1, root.position / root.length) : 0
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 32

            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                text: "⏮"
                color: prevMa.containsMouse ? C.accent : C.textDim
                font.pixelSize: 22
                MouseArea { id: prevMa; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { ctlProc.command = ["playerctl", "previous"]; ctlProc.running = true } }
            }
            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                text: root.status === "Playing" ? "⏸" : "▶"
                color: ppMa.containsMouse ? C.accent : C.text
                font.pixelSize: 28
                MouseArea { id: ppMa; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { ctlProc.command = ["playerctl", "play-pause"]; ctlProc.running = true; pollProc.running = true } }
            }
            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                text: "⏭"
                color: nextMa.containsMouse ? C.accent : C.textDim
                font.pixelSize: 22
                MouseArea { id: nextMa; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { ctlProc.command = ["playerctl", "next"]; ctlProc.running = true } }
            }
        }

        Item { Layout.fillHeight: true }
    }

    Process { id: ctlProc }

    // Cava visualizer — only runs while this page is actually shown
    Process {
        id: cavaProc
        running: root.active
        command: ["sh", "-c", "exec cava -p ~/.config/quickshell/cava/config"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var vals = line.split(";").filter(s => s.length > 0)
                if (vals.length > 0)
                    root.cavaBars = vals.map(v => parseFloat(v) || 0)
            }
        }
    }
    onActiveChanged: if (!active) cavaBars = []

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: pollProc.running = true }
    Process {
        id: pollProc
        command: ["sh", "-c",
            "playerctl metadata --format '{{status}}|||{{artist}}|||{{title}}|||{{mpris:artUrl}}|||{{position}}|||{{mpris:length}}' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.replace(/\n$/, "").split("|||")
                if (parts.length >= 6) {
                    root.status   = parts[0]
                    root.artist   = parts[1]
                    root.title    = parts[2]
                    root.artUrl   = parts[3]
                    root.position = (parseFloat(parts[4]) || 0) / 1000000
                    root.length   = (parseFloat(parts[5]) || 0) / 1000000
                } else {
                    root.title = ""; root.artist = ""; root.artUrl = ""; root.status = ""
                }
            }
        }
    }
}
