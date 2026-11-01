import QtQuick
import "../ds"
import "../ds/primitives"
import "../strings"

// The top bar's unread counter (spec 008, FR-025): a small square, LOG (DND with do not disturb on)
// and the number of unread transmissions, before the clock. Hidden with nothing unread and do not
// disturb off. It follows the bar's tone (spec 004 US6: ink over paper, light over a dark wallpaper)
// through `ink`; with Bar contrast: High, a paper plate behind it (`plate`, `plated`), as the bar's
// other texts. A click opens the text log.
Item {
    id: root

    property real s: 1
    property real tone: 0
    property int count: 0
    property bool dnd: false
    property color ink: Tokens.hudColor("ink", tone)
    property color plate: "transparent"
    property bool plated: false

    signal clicked()

    readonly property Label labelText: label
    readonly property Label valueText: value

    visible: count > 0 || dnd
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Rectangle {
        x: -3
        y: -2
        width: root.width + 6
        height: root.height + 4
        visible: root.plated
        color: root.plate
    }

    Row {
        id: row
        spacing: Tokens.px(6, root.s)

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.px(Tokens.notify.counterSquare, root.s)
            height: width
            color: root.ink
        }
        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            tone: root.tone
            role: "small"
            text: root.dnd ? Strings.notify.counterDnd : Strings.notify.counterLog
            color: root.ink
        }
        Label {
            id: value
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            tone: root.tone
            role: "small"
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": Font.DemiBold })
            font.features: ({ "tnum": 1 })
            text: String(root.count)
            color: root.ink
        }

    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Tokens.px(4, root.s)
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
