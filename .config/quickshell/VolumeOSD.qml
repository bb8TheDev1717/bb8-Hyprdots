import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "colors.js" as C

PanelWindow {
    id: osd

    property real volume: 0
    property bool muted: false
    property bool shown: false

    screen: {
        var best = null
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (best === null || s.width > best.width) best = s
        }
        return best
    }

    // Bottom-anchored only (no left/right) — wlr-layer-shell centers the
    // surface horizontally by default when the opposite edges aren't anchored.
    anchors { bottom: true }
    margins { bottom: 90 }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-volume-osd"

    implicitWidth: 220
    implicitHeight: 64

    // Purely informational — never intercepts clicks.
    mask: Region { width: 0; height: 0 }

    Timer {
        id: hideTimer
        interval: 1300
        onTriggered: osd.shown = false
    }

    Component.onCompleted: refresh()

    // Last known values, so we can tell a REAL volume/mute change apart from
    // pactl's "change on sink" event, which also fires when a stream simply
    // starts/stops playing (sink RUNNING/IDLE) — not just on volume changes.
    property real lastVolume: -1
    property bool lastMuted: false
    property bool haveBaseline: false

    function refresh() { volProc.running = true }

    // Reacts to ANY volume change (media keys, mixer, scroll on a tray icon,
    // …) rather than only ones triggered through our own keybinds.
    Process {
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (line.indexOf("change' on sink") !== -1) osd.refresh()
            }
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                var newMuted = t.indexOf("MUTED") !== -1
                var m = t.match(/([0-9.]+)/)
                var newVolume = m ? Math.round(parseFloat(m[1]) * 100) : 0

                // First read after startup just establishes the baseline —
                // don't pop the OSD up on launch.
                var realChange = osd.haveBaseline &&
                    (newVolume !== osd.lastVolume || newMuted !== osd.lastMuted)

                osd.volume = newVolume
                osd.muted = newMuted
                osd.lastVolume = newVolume
                osd.lastMuted = newMuted
                osd.haveBaseline = true

                if (realChange) {
                    osd.shown = true
                    hideTimer.restart()
                }
            }
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 200
        height: 56
        radius: 16
        color: Qt.rgba(0x0D / 255, 0x0D / 255, 0x12 / 255, 0.65)
        border.width: 1
        border.color: C.border

        scale: osd.shown ? 1.0 : 0.85
        opacity: osd.shown ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                font.family: "Noto Sans"
                text: osd.muted ? "🔇" : osd.volume > 60 ? "🔊" : osd.volume > 0 ? "🔉" : "🔈"
                font.pixelSize: 20
                color: C.text
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: C.surfaceHi
                Rectangle {
                    height: parent.height
                    radius: 3
                    width: parent.width * Math.min(1, osd.volume / 100)
                    color: osd.muted ? C.textMuted : C.accent
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                }
            }

            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                text: osd.muted ? "Stumm" : osd.volume + "%"
                color: C.textDim
                font.pixelSize: 12
                Layout.preferredWidth: 44
            }
        }
    }
}
