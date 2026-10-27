import QtQuick
import ".."

// The flat hp-bar (FR-007): a lightGray track with an ink fill proportional to `value`.
// Value changes animate (instantly while frozen); `critical` paints the fill in `alert`.
Rectangle {
    id: root

    property real s: 1
    property real value: 0                       // 0–1, clamped
    property bool critical: false
    property real w: Tokens.space.meterW         // game px
    property real h: Tokens.space.meterH

    readonly property real clamped: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    implicitWidth: Tokens.px(w, s)
    implicitHeight: Tokens.px(h, s)
    color: Tokens.color.lightGray

    Rectangle {
        height: parent.height
        width: Math.round(root.width * root.clamped)
        color: root.critical ? Tokens.color.alert : Tokens.color.darkGray

        Behavior on width {
            enabled: !Tokens.frozen
            NumberAnimation { duration: Tokens.motion.meter; easing.type: Easing.OutCubic }
        }
    }
}
