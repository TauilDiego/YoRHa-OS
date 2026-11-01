import QtQuick
import ".."
import "../primitives"

// A small tag (spec 008): CRITICAL (light text on `alert`, next to the speaker; FR-010) or NEW (an
// outline of 1.5 px in the text's color, on a log row while the log is open).
//   fill: the tag's ground ("transparent" for an outline tag); outline: draw the outline.
Rectangle {
    id: root

    property real s: 1
    property string text
    property color fill: Tokens.color.alert
    property bool outline: false
    property color ink: Tokens.notify.bandText
    property real dpr: 1

    implicitWidth: label.implicitWidth + 2 * Tokens.px(outline ? 4 : 8, s)
    implicitHeight: Math.round(label.size + Tokens.px(outline ? 5 : 9, s))
    color: outline ? "transparent" : fill
    border.width: outline ? Tokens.hair(1.5 * s, dpr) : 0
    border.color: ink

    Label {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Tokens.px(0.5, root.s)
        s: root.s
        role: "bandTag"
        font.pixelSize: root.outline ? Math.max(1, Tokens.px(12, root.s)) : size
        text: root.text
        color: root.ink
    }
}
