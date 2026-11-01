import QtQuick
import ".."
import "../primitives"

// An action button on the band (spec 008, FR-012): a light 2 px outline and the `bandAction` text.
// With the pointer over it (or `on`), the light ink sweeps in from the left (Tokens.notify.sweep)
// and the text turns dark; `enabled: false` draws it at 35% and takes no clicks.
Item {
    id: root

    property real s: 1
    property string text
    property bool on: false
    property real dpr: 1

    signal clicked()

    readonly property bool lit: on || (enabled && mouse.containsMouse)
    property real sweep: lit ? 1 : 0
    Behavior on sweep {
        enabled: !Tokens.instant
        NumberAnimation { duration: Tokens.notify.sweep; easing.type: Easing.OutCubic }
    }

    implicitWidth: label.implicitWidth + 2 * Tokens.px(Tokens.notify.actionPad, s)
    implicitHeight: Tokens.px(Tokens.notify.actionH, s)
    opacity: enabled ? 1 : 0.35

    Rectangle {
        width: Math.round(root.width * root.sweep)
        height: root.height
        color: Tokens.notify.bandText
    }
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: Tokens.hair(Tokens.notify.line * root.s, root.dpr)
        border.color: Tokens.notify.bandText
    }
    Label {
        id: label
        anchors.centerIn: parent
        s: root.s
        role: "bandAction"
        text: root.text
        color: root.sweep > 0.5 ? Tokens.color.darkGray : Tokens.notify.bandText
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
