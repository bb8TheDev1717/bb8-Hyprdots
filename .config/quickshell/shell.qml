import Quickshell
import QtQuick

ShellRoot {
    Bar { id: bar }
    Overlay {
        id: overlay
        barMenu: bar.activeMenu
        onCloseBarRequested: bar.activeMenu = ""
    }
    Notification {}
    VolumeOSD {}
}
