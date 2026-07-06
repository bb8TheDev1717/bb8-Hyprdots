import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "colors.js" as C

PanelWindow {
    id: bar

    // Pin to the widest monitor (the 3840px ultrawide), not a random default
    screen: {
        var best = null
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (best === null || s.width > best.width) best = s
        }
        return best
    }

    anchors { top: true; left: true; right: true }
    margins { left: 900; right: 900 }

    property real barHeight: 40
    property real popupOverlap: 24

    // Single centered popup hub (constant geometry); pages slide horizontally
    readonly property real popupW: 460
    readonly property real popupH: 430

    // Which menu is open: "" | "control" | "calendar" | "player"
    property string activeMenu: ""
    readonly property bool popupOpen: activeMenu !== ""
    property int pageIndex: 2   // 0 = player, 1 = calendar, 2 = control

    function clockLabel() {
        var d = new Date()
        return Qt.formatDateTime(d, "HH:mm") + " <font color=\"" + C.textDim + "\">|</font> " + Qt.formatDateTime(d, "dd.MM")
    }

    function menuIndex(n) { return n === "player" ? 0 : n === "calendar" ? 1 : 2 }
    function indexMenu(i) { return i === 0 ? "player" : i === 1 ? "calendar" : "control" }

    // Jumps straight to the target page when opening from closed (no slide —
    // there's nothing visible to slide from), but still slides smoothly when
    // switching between pages while the popup is already open.
    function setMenu(name) {
        var wasOpen = activeMenu !== ""
        if (!wasOpen) pagerXBehavior.enabled = false
        pageIndex = menuIndex(name)
        if (!wasOpen) pagerXBehavior.enabled = true
        activeMenu = name
    }

    function toggleMenu(name) {
        if (activeMenu === name) { activeMenu = ""; return }
        setMenu(name)
    }
    function openMenuByName(name) { toggleMenu(name) }

    property real popupProgress: 0
    Behavior on popupProgress { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
    onActiveMenuChanged: popupProgress = (activeMenu !== "") ? 1.0 : 0.0

    // Id of the workspace currently active on THIS bar's monitor.
    // (ws.focused is only true on the globally focused monitor — wrong for a per-monitor bar.
    //  Quickshell's ObjectModel exposes .values (a JS array), there is no .count.)
    readonly property int activeWsId: {
        if (!screen) return -1
        var ws = Hyprland.workspaces.values
        for (var i = 0; i < ws.length; i++)
            if (ws[i].active && ws[i].monitor && ws[i].monitor.name === screen.name)
                return ws[i].id
        return -1
    }

    implicitHeight: barHeight + popupH + popupOverlap + 20
    color: "transparent"
    exclusiveZone: barHeight

    // Only grab keyboard focus while a popup is open, so we never steal focus
    // from whatever app the user is actually working in.
    WlrLayershell.keyboardFocus: bar.popupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    onPopupOpenChanged: if (popupOpen) keyCatcher.forceActiveFocus()

    mask: Region {
        x: 0; y: 0
        width: bar.width
        height: bar.barHeight + bar.popupProgress * (bar.popupH + bar.popupOverlap)
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { bar.toggleMenu("control") }
        function open(): void   { bar.setMenu("control") }
        function close(): void  { bar.activeMenu = "" }
        function isOpen(): string { return bar.popupOpen ? "1" : "0" }
    }

    IpcHandler {
        target: "bar"
        function menu(name: string): void { bar.openMenuByName(name) }
        function close(): void { bar.activeMenu = "" }
        function active(): string { return bar.activeMenu }
    }

    // ── Blob shader (bar + centered popup, merged) ───────────────────────────
    ShaderEffect {
        id: blob
        anchors.fill: parent

        property real resW: width
        property real resH: height
        property real barCx: width / 2
        property real barCy: bar.barHeight / 2
        property real barHw: width / 2
        property real barHh: bar.barHeight / 2

        property real popupHh: bar.popupProgress * (bar.popupH / 2 + bar.popupOverlap / 2)
        property real popupCy: bar.barHeight - bar.popupOverlap + popupHh
        property real popupHw: bar.popupW / 2
        property real popupCx: width / 2

        property real barRadius:    20
        property real popupRadius:  20
        property real smoothFactor: 14
        property color color: Qt.rgba(0x0D / 255, 0x0D / 255, 0x12 / 255, 0.65)

        vertexShader:   "shaders/blob.vert.qsb"
        fragmentShader: "shaders/blob.frag.qsb"
    }

    // Escape always closes; clicking anywhere in this window that isn't
    // consumed by the bar/popup content (declared below, so on top) closes too.
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: bar.popupOpen
        Keys.onEscapePressed: bar.activeMenu = ""
    }
    MouseArea {
        anchors.fill: parent
        enabled: bar.popupOpen
        onClicked: bar.activeMenu = ""
    }

    // ── Bar content ──────────────────────────────────────────────────────────
    Item {
        id: barContent
        x: 0; y: 0
        width: parent.width
        height: bar.barHeight

        // Left: workspaces + media
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Repeater {
                model: 11
                delegate: Item {
                    required property int index
                    property int wsId: index + 1
                    property var ws: {
                        var arr = Hyprland.workspaces.values
                        for (var i = 0; i < arr.length; i++)
                            if (arr[i].id === wsId) return arr[i]
                        return null
                    }
                    property bool isActive:   bar.activeWsId === wsId
                    property bool hasWindows: ws !== null && ws.toplevels.count > 0
                    property bool show:       wsId <= 5 || isActive || hasWindows

                    visible:        show
                    implicitWidth:  show ? Math.max(24, lbl.implicitWidth + 16) : 0
                    implicitHeight: 24

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: isActive ? C.accent : hasWindows ? C.surfaceHi : "transparent"
                        opacity: isActive ? 1.0 : hasWindows ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Behavior on color  { ColorAnimation  { duration: 150 } }
                    }

                    Text {
                        font.family: "Noto Sans"
                        id: lbl
                        anchors.centerIn: parent
                        text: wsId
                        color: isActive ? C.bg : hasWindows ? C.text : C.textMuted
                        font.pixelSize: 12
                        font.weight: isActive ? Font.Bold : Font.Normal
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        // This Hyprland build wraps hyprctl dispatch in Lua — a bare
                        // "workspace N" payload isn't valid Lua, it has to be the
                        // actual dispatcher call expression (see keybinds.lua's own
                        // `hl.dsp.focus({ workspace = i })` for workspace keybinds).
                        onClicked: ws !== null ? ws.activate() : Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
                    }
                }
            }

            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                id: mediaText
                Layout.maximumWidth: 240
                elide: Text.ElideRight
                visible: text.length > 0
                text: ""
                color: C.text
                font.pixelSize: 12
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.toggleMenu("player")
                }
            }
        }

        // Center: clock (opens calendar)
        Text {
            font.family: "Noto Sans"
            id: clockText
            anchors.centerIn: parent
            textFormat: Text.StyledText
            text: bar.clockLabel()
            color: C.text
            font.pixelSize: 13
            font.weight: Font.Medium
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: clockText.text = bar.clockLabel()
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.toggleMenu("calendar")
            }
        }

        // Right: net speed + OwO (opens control center)
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            RowLayout {
                spacing: 8
                Text { id: netUp;   text: "↑ --"; color: C.textDim; font.pixelSize: 12 }
                Text { id: netDown; text: "↓ --"; color: C.textDim; font.pixelSize: 12 }
            }

            Text {
                font.family: "Noto Sans"
                id: owoBtn
                text: "OwO"
                color: bar.activeMenu === "control" ? C.accent : C.accentDim
                font.pixelSize: 13
                font.weight: Font.Bold
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.toggleMenu("control")
                }
            }
        }
    }

    // ── Popup hub: centered, pages slide to the triggered one ────────────────
    Item {
        id: popupContent
        width: bar.popupW
        height: bar.popupH
        x: (bar.width - width) / 2
        y: bar.barHeight
        // Content fades in during the LATTER part of the growth animation, not
        // linearly with it, so it doesn't look "done" before the container has
        // visibly finished growing. Pushed further back than before — at a 0.3
        // start it still crossed ~50% opacity while the container was only
        // ~65% grown, which read as arriving "together"; 0.55 keeps content
        // clearly behind until the container is most of the way there.
        opacity: Math.max(0, (bar.popupProgress - 0.55) / 0.45)
        visible: bar.popupProgress > 0.01
        clip: true

        Row {
            id: pager
            height: parent.height
            x: -bar.pageIndex * popupContent.width
            Behavior on x {
                id: pagerXBehavior
                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
            }

            Item { width: popupContent.width; height: popupContent.height
                PlayerCtl { anchors.fill: parent; active: bar.activeMenu === "player" } }
            Item { width: popupContent.width; height: popupContent.height; Calender  { anchors.fill: parent } }
            Item { width: popupContent.width; height: popupContent.height
                ControlPopup { anchors.fill: parent; onRequestClose: bar.activeMenu = "" } }
        }

        // Wheel scrolls between pages without blocking clicks (NoButton = pass-through)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (w) => {
                var d = w.angleDelta.y > 0 ? -1 : 1
                var ni = Math.max(0, Math.min(2, bar.pageIndex + d))
                if (ni !== bar.pageIndex) { bar.pageIndex = ni; bar.activeMenu = bar.indexMenu(ni) }
            }
        }
    }

    // ── Network speed ────────────────────────────────────────────────────────
    property var netPrev: null
    Timer { interval: 1000; running: true; repeat: true; onTriggered: netProc.running = true }
    Process {
        id: netProc
        command: ["sh", "-c", "cat /proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                var rx = 0, tx = 0
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i].trim()
                    if (/^(enp|wlp|eth|wlan|eno|ens)/.test(l)) {
                        var p = l.split(/\s+/)
                        rx += parseInt(p[1]) || 0
                        tx += parseInt(p[9]) || 0
                    }
                }
                if (bar.netPrev !== null) {
                    netDown.text = "↓ " + bar.fmt(rx - bar.netPrev.rx)
                    netUp.text   = "↑ " + bar.fmt(tx - bar.netPrev.tx)
                }
                bar.netPrev = { rx: rx, tx: tx }
            }
        }
    }
    function fmt(b) {
        if (b < 0)       b = 0
        if (b < 1024)    return b + " B/s"
        if (b < 1048576) return (b / 1024).toFixed(1) + " kB/s"
        return (b / 1048576).toFixed(1) + " MB/s"
    }

    // ── Media (playerctl) — bar label ────────────────────────────────────────
    Timer { interval: 1500; running: true; repeat: true; triggeredOnStart: true; onTriggered: mediaProc.running = true }
    Process {
        id: mediaProc
        command: ["sh", "-c", "playerctl metadata --format '{{ artist }} - {{ title }}' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                mediaText.text = (t === " - " || t === "-") ? "" : t
            }
        }
    }
}
