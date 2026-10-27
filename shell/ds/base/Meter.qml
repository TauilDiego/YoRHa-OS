import QtQuick
import ".."

// The flat hp-bar (FR-007): a lightGray track with an ink fill proportional to `value`.
// Value changes animate (instantly while frozen); `critical` paints the fill in `alert`.
// spec 003, the settings slider: `editable` turns a press or a drag on the track into
// picked(0–1); `inverted` is for an ink band (mediumGray track, lightYellow fill).
// spec 004 US6: `tone` is the top bar's tone (0 paper → 1 light) for track, fill and alert.
Rectangle {
    id: root

    property real s: 1
    property real value: 0                       // 0–1, clamped
    property bool critical: false
    property real w: Tokens.space.meterW         // game px
    property real h: Tokens.space.meterH
    property bool editable: false
    property bool inverted: false
    property real tone: 0

    signal picked(real value)

    readonly property real clamped: Math.max(0, Math.min(1, isNaN(value) ? 0 : value))

    implicitWidth: Tokens.px(w, s)
    implicitHeight: Tokens.px(h, s)
    color: inverted ? Tokens.color.mediumGray : Tokens.hudColor("track", tone)

    Rectangle {
        height: parent.height
        width: Math.round(root.width * root.clamped)
        color: root.critical ? Tokens.hudColor("alert", root.tone)
                             : root.inverted ? Tokens.color.lightYellow : Tokens.hudColor("fill", root.tone)

        Behavior on width {
            enabled: !Tokens.frozen
            NumberAnimation { duration: Tokens.motion.meter; easing.type: Easing.OutCubic }
        }
    }

    // The track is thin: the hit area reaches a little above and below it.
    MouseArea {
        anchors.fill: parent
        anchors.topMargin: -Tokens.px(12, root.s)
        anchors.bottomMargin: -Tokens.px(12, root.s)
        enabled: root.editable
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.picked(Math.max(0, Math.min(1, mouse.x / root.width)))
        onPositionChanged: mouse => {
            if (pressed)
                root.picked(Math.max(0, Math.min(1, mouse.x / root.width)));
        }
    }
}
