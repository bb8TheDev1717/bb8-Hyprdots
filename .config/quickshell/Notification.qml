import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "colors.js" as C

Scope {
    id: scope

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        onNotification: (n) => { n.tracked = true }
    }

    PanelWindow {
        id: win
        screen: {
            var best = null
            for (var i = 0; i < Quickshell.screens.length; i++) {
                var s = Quickshell.screens[i]
                if (best === null || s.width > best.width) best = s
            }
            return best
        }
        anchors { top: true; right: true }
        margins { top: 14; right: 14 }
        color: "transparent"
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: Math.max(1, col.implicitHeight)
        visible: server.trackedNotifications.values.length > 0

        mask: Region { item: col }

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 10

            Repeater {
                model: server.trackedNotifications

                delegate: Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: inner.implicitHeight + 28
                    radius: 16
                    color: Qt.rgba(0x12 / 255, 0x12 / 255, 0x18 / 255, 0.65)
                    border.width: 1
                    border.color: modelData.urgency === NotificationUrgency.Critical ? C.red : C.border

                    RowLayout {
                        id: inner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 14
                        spacing: 12

                        // App icon / image
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignTop
                            radius: 10
                            color: C.surface
                            visible: img.source.toString().length > 0
                            clip: true
                            Image {
                                id: img
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                source: card.modelData.image !== "" ? card.modelData.image
                                      : card.modelData.appIcon !== "" ? card.modelData.appIcon : ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    font.family: "Noto Sans"
                                    Layout.fillWidth: true
                                    text: card.modelData.summary
                                    color: C.text
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    font.family: "Noto Sans"
                                    font.weight: Font.DemiBold
                                    text: card.modelData.appName
                                    color: C.textMuted
                                    font.pixelSize: 10
                                }
                            }
                            Text {
                                font.family: "Noto Sans"
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                text: card.modelData.body
                                color: C.textDim
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.modelData.dismiss()
                    }

                    Timer {
                        running: true
                        interval: {
                            var t = card.modelData.expireTimeout
                            return t > 0 ? t : (card.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000)
                        }
                        onTriggered: card.modelData.dismiss()
                    }
                }
            }
        }
    }
}
