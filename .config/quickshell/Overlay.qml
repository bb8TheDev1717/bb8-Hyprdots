import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "colors.js" as C
import "pinnedApps.js" as Pinned

PanelWindow {
    id: overlay

    // Mirrors Bar.activeMenu (wired from shell.qml) so this window can also
    // catch outside-clicks / Escape for the bar's own popup hub.
    property string barMenu: ""
    signal closeBarRequested()

    property bool launcherOpen: false
    property bool wallpaperOpen: false
    property string query: ""
    property int selectedIndex: 0
    property var apps: []

    // Backing model for the visible list. We diff into this in place (insert /
    // move / remove) instead of reassigning a whole new array every keystroke —
    // a full reassignment destroys and recreates every delegate (icons included),
    // which is what caused the flicker on each keypress. Untouched rows now keep
    // their delegate instance (and their already-loaded Image) across filtering.
    ListModel { id: appsModel }

    readonly property bool anyOpen: launcherOpen || barMenu !== "" || wallpaperOpen

    screen: {
        var best = null
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i]
            if (best === null || s.width > best.width) best = s
        }
        return best
    }

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    // The launcher needs to be typable the instant it opens, without the user
    // having to click it first — OnDemand only grants focus on interaction,
    // Exclusive grabs it immediately (same as rofi/wofi/anyrun do).
    WlrLayershell.keyboardFocus: overlay.launcherOpen ? WlrKeyboardFocus.Exclusive
                                : overlay.wallpaperOpen ? WlrKeyboardFocus.Exclusive
                                : overlay.barMenu !== "" ? WlrKeyboardFocus.OnDemand
                                : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-overlay"

    onLauncherOpenChanged: if (launcherOpen) keyCatcher.forceActiveFocus()
    onWallpaperOpenChanged: if (wallpaperOpen) keyCatcher.forceActiveFocus()
    onBarMenuChanged: if (barMenu !== "") keyCatcher.forceActiveFocus()

    mask: Region {
        x: 0; y: 0
        width: overlay.anyOpen ? overlay.width : 0
        height: overlay.anyOpen ? overlay.height : 0
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { overlay.toggleLauncher() }
        function open(): void   { overlay.openLauncher() }
        function close(): void  { overlay.launcherOpen = false }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { overlay.wallpaperOpen = !overlay.wallpaperOpen }
        function open(): void   { overlay.wallpaperOpen = true }
        function close(): void  { overlay.wallpaperOpen = false }
    }

    function toggleLauncher() {
        if (launcherOpen) { launcherOpen = false; return }
        openLauncher()
    }
    function openLauncher() {
        query = ""
        selectedIndex = 0
        refreshApps()
        launcherOpen = true
    }
    function refreshApps() { appsProc.running = true }

    function applyFilter() {
        var q = query.toLowerCase()
        var pinnedNames = Pinned.pinned.map(function (s) { return s.toLowerCase() })
        var pinnedList = [], rest = []
        for (var i = 0; i < apps.length; i++) {
            var a = apps[i]
            if (q.length > 0 && a.name.toLowerCase().indexOf(q) === -1) continue
            if (pinnedNames.indexOf(a.name.toLowerCase()) !== -1) pinnedList.push(a)
            else rest.push(a)
        }
        pinnedList.sort(function (a, b) {
            return pinnedNames.indexOf(a.name.toLowerCase()) - pinnedNames.indexOf(b.name.toLowerCase())
        })
        var newList = pinnedList.concat(rest)

        // Diff `newList` into appsModel in place (see comment at the property
        // declaration) instead of replacing the model wholesale.
        var wanted = {}
        for (var i = 0; i < newList.length; i++) wanted[newList[i].name] = true

        for (var i = appsModel.count - 1; i >= 0; i--) {
            if (!wanted[appsModel.get(i).name]) appsModel.remove(i)
        }

        for (var i = 0; i < newList.length; i++) {
            var entry = newList[i]
            var curIndex = -1
            for (var j = 0; j < appsModel.count; j++) {
                if (appsModel.get(j).name === entry.name) { curIndex = j; break }
            }
            if (curIndex === -1) {
                appsModel.insert(i, entry)
            } else if (curIndex !== i) {
                appsModel.move(curIndex, i, 1)
            }
        }

        selectedIndex = 0
    }

    function moveSelection(d) {
        if (appsModel.count === 0) return
        selectedIndex = Math.max(0, Math.min(appsModel.count - 1, selectedIndex + d))
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function launchSelected() {
        if (appsModel.count === 0 || selectedIndex >= appsModel.count) return
        var entry = appsModel.get(selectedIndex)
        launchProc.command = ["sh", "-c", entry.exec + " >/dev/null 2>&1 &"]
        launchProc.running = true
        launcherOpen = false
    }

    Process { id: launchProc }

    Process {
        id: appsProc
        command: ["sh", "-c", "exec python3 -u ~/.config/quickshell/list_apps.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n").filter(function (l) { return l.length > 0 })
                overlay.apps = lines.map(function (l) {
                    var p = l.split("|||")
                    return { name: p[0] || "", exec: p[1] || "", icon: p[2] || "" }
                })
                overlay.applyFilter()
            }
        }
    }

    // ── Input handling: Escape always closes; arrows/enter drive the list ────
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: overlay.anyOpen

        Keys.onEscapePressed: { overlay.launcherOpen = false; overlay.wallpaperOpen = false; overlay.closeBarRequested() }
        Keys.onDownPressed:   if (overlay.launcherOpen) overlay.moveSelection(1)
        Keys.onUpPressed:     if (overlay.launcherOpen) overlay.moveSelection(-1)
        Keys.onReturnPressed: if (overlay.launcherOpen) overlay.launchSelected()
        Keys.onEnterPressed:  if (overlay.launcherOpen) overlay.launchSelected()

        Keys.onPressed: (event) => {
            if (!overlay.launcherOpen) return
            if (event.text.length > 0 && event.key !== Qt.Key_Backspace) {
                overlay.query += event.text
                overlay.applyFilter()
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                overlay.query = overlay.query.slice(0, -1)
                overlay.applyFilter()
                event.accepted = true
            }
        }
    }

    // Dim + click-outside-closes background (only visually dims for the launcher/wallpaper picker)
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }
    MouseArea {
        anchors.fill: parent
        enabled: overlay.anyOpen
        onClicked: { overlay.launcherOpen = false; overlay.wallpaperOpen = false; overlay.closeBarRequested() }
    }

    // ── Rofi-style launcher panel: pops from tiny to full size ───────────────
    Rectangle {
        id: panel
        width: 560
        height: 76 + Math.min(6, Math.max(1, appsModel.count)) * 46
        anchors.centerIn: parent
        radius: 18
        color: Qt.rgba(0x0D / 255, 0x0D / 255, 0x12 / 255, 0.68)
        border.width: 1
        border.color: C.border
        clip: true

        visible: scale > 0.02
        scale: overlay.launcherOpen ? 1.0 : 0.05
        opacity: overlay.launcherOpen ? 1.0 : 0.0
        Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        // Smooth resize as the filtered result count grows/shrinks while typing,
        // instead of snapping to the new height instantly.
        Behavior on height  { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

        // Swallow clicks so interacting with the panel doesn't close it.
        MouseArea { anchors.fill: parent; onClicked: (m) => {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: "⌕"; color: C.accent; font.pixelSize: 20 }
                Text {
                    font.family: "Noto Sans"
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    text: overlay.query.length > 0 ? overlay.query : "App suchen…"
                    color: overlay.query.length > 0 ? C.text : C.textMuted
                    font.pixelSize: 16
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: C.border }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: appsModel
                spacing: 2
                currentIndex: overlay.selectedIndex

                // Sliding selection highlight (instead of each row's background
                // snapping between colors) — glides between rows smoothly.
                highlight: Rectangle { radius: 10; color: C.surfaceHi }
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 120
                highlightResizeDuration: 120

                // Rows that stay in the result set across keystrokes are only
                // moved (see applyFilter's diff), not destroyed — so only truly
                // new/removed rows animate in/out here, nothing flickers.
                add: Transition {
                    NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutQuad }
                }
                remove: Transition {
                    NumberAnimation { properties: "opacity"; to: 0; duration: 100 }
                }
                move: Transition {
                    NumberAnimation { properties: "y"; duration: 140; easing.type: Easing.OutQuad }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 140; easing.type: Easing.OutQuad }
                }

                delegate: Rectangle {
                    id: row
                    required property string name
                    required property string exec
                    required property string icon
                    required property int index
                    width: list.width
                    height: 42
                    radius: 10
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            width: 26; height: 26; radius: 8
                            color: C.surface
                            clip: true

                            Image {
                                id: iconImg
                                anchors.fill: parent
                                anchors.margins: 3
                                source: row.icon.length > 0 ? "file://" + row.icon : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: row.icon.length > 0 && status === Image.Ready
                            }
                            Text {
                                font.family: "Noto Sans"
                                anchors.centerIn: parent
                                visible: !iconImg.visible
                                text: row.name.length > 0 ? row.name.charAt(0).toUpperCase() : "?"
                                color: C.accent
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }
                        Text {
                            font.family: "Noto Sans"
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            text: row.name
                            color: C.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: overlay.selectedIndex = row.index
                        onClicked: { overlay.selectedIndex = row.index; overlay.launchSelected() }
                    }
                }

                Text {
                    font.family: "Noto Sans"
                    font.weight: Font.DemiBold
                    anchors.centerIn: parent
                    visible: appsModel.count === 0
                    text: "Keine Treffer"
                    color: C.textMuted
                    font.pixelSize: 13
                }
            }
        }
    }

    // ── Wallpaper picker: same pop-from-center effect, much bigger panel ────
    Rectangle {
        id: wallpaperPanel
        width: overlay.width * 0.7
        height: overlay.height * 0.75
        anchors.centerIn: parent
        radius: 18
        color: Qt.rgba(0x0D / 255, 0x0D / 255, 0x12 / 255, 0.65)
        border.width: 1
        border.color: C.border
        clip: true

        visible: scale > 0.02
        scale: overlay.wallpaperOpen ? 1.0 : 0.05
        opacity: overlay.wallpaperOpen ? 1.0 : 0.0
        Behavior on scale   { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea { anchors.fill: parent; onClicked: (m) => {} }

        WallpaperSelector {
            anchors.fill: parent
            onWallpaperApplied: overlay.wallpaperOpen = false
        }
    }
}
