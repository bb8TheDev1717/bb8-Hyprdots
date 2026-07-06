import QtQuick
import QtQuick.Layouts
import "colors.js" as C

Item {
    id: root

    property var today: new Date()
    property int viewYear:  today.getFullYear()
    property int viewMonth: today.getMonth()   // 0-11

    readonly property var monthNames: ["Januar","Februar","März","April","Mai","Juni",
                                       "Juli","August","September","Oktober","November","Dezember"]

    function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
    // Monday-first offset of the 1st of the month
    function firstOffset(y, m) { var d = new Date(y, m, 1).getDay(); return (d + 6) % 7 }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear-- } else viewMonth--
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++ } else viewMonth++
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            Text {
                font.family: "Noto Sans"
                text: monthNames[viewMonth] + " " + viewYear
                color: C.text
                font.pixelSize: 15
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                text: "‹"
                color: lMa.containsMouse ? C.accent : C.textDim
                font.pixelSize: 20
                MouseArea { id: lMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.prevMonth() }
            }
            Text {
                font.family: "Noto Sans"
                font.weight: Font.DemiBold
                text: "›"
                color: rMa.containsMouse ? C.accent : C.textDim
                font.pixelSize: 20
                MouseArea { id: rMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nextMonth() }
            }
        }

        // Weekday header
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 0
            Repeater {
                model: ["Mo","Di","Mi","Do","Fr","Sa","So"]
                delegate: Item {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    Text {
                        font.family: "Noto Sans"
                        anchors.centerIn: parent
                        text: modelData
                        color: index >= 5 ? C.accentDim : C.textMuted
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }
            }
        }

        // Day grid (6 weeks × 7)
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: 42
                delegate: Item {
                    required property int index
                    property int dayNum: index - root.firstOffset(root.viewYear, root.viewMonth) + 1
                    property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth(root.viewYear, root.viewMonth)
                    property bool isToday: inMonth
                                           && dayNum === root.today.getDate()
                                           && root.viewMonth === root.today.getMonth()
                                           && root.viewYear === root.today.getFullYear()

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 2
                        height: width
                        radius: width / 2
                        color: isToday ? C.accent : "transparent"
                        Text {
                            font.family: "Noto Sans"
                            anchors.centerIn: parent
                            text: inMonth ? dayNum : ""
                            color: isToday ? C.bg : inMonth ? C.text : C.textMuted
                            font.pixelSize: 12
                            font.weight: isToday ? Font.Bold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
