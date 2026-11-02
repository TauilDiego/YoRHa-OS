import QtQuick
import "../ds"
import "../ds/primitives"
import "../strings"

// The top bar's update sign (spec 015, contracts/sinal.md): a small square, UPDATE and the newer
// version, before the LOG counter, while Updater.signBar (a newer version, with the sign's form Bar or
// Bar and menu). Modelled on LogCounter: the bar's tone through `ink`, and with Bar contrast: High the
// paper plate behind it (`plate`, `plated`). A click opens SYSTEM › Updates.
Item {
    id: root

    property real s: 1
    property real tone: 0
    property bool shown: false
    property string version: ""
    property color ink: Tokens.hudColor("ink", tone)
    property color plate: "transparent"
    property bool plated: false

    signal clicked()

    readonly property Label labelText: label
    readonly property Label valueText: value

    visible: shown && version !== ""
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
            text: Strings.updates.barTag
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
            text: root.version
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
