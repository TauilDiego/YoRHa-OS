import QtQuick
import ".."

// Text that does not fit (spec 013, FR-012): a Label in a clipping box. A text wider than the box
// holds Tokens.motion.marqueeHold, scrolls to its end (+4 px) at marqueeSpeed game px/s, holds
// again and jumps back to the start, over and over; a text that fits stays put. With
// Tokens.instant (Reduce motion, fixtures) it is cut with an ellipsis instead (FR-016).
//   follow: another ScrollingLabel whose offset this one copies, so two copies of one text scroll
//     as one (the ListItem's dark and light faces);
//   running: false parks it at the start.
// The parent sets the width; without one the box is as wide as the text and nothing scrolls.
Item {
    id: root

    property alias s: inner.s
    property alias role: inner.role
    property alias text: inner.text
    property alias color: inner.color
    property alias upper: inner.upper
    property alias tone: inner.tone
    readonly property alias label: inner         // font tweaks (weight, axes) by the caller
    property bool running: true
    property var follow: null                    // a ScrollingLabel

    readonly property bool overflows: inner.implicitWidth > width + 0.5
    readonly property real distance: overflows ? Math.ceil(inner.implicitWidth - width + Tokens.px(4, s)) : 0
    readonly property bool scrolls: running && overflows && !Tokens.instant && follow === null && visible
    property real offset: 0

    implicitWidth: inner.implicitWidth
    implicitHeight: inner.implicitHeight
    clip: overflows

    function restart(): void {
        loop.stop();
        offset = 0;
        if (scrolls)
            loop.start();
    }
    onScrollsChanged: restart()
    onDistanceChanged: restart()
    onTextChanged: restart()

    Label {
        id: inner
        anchors.verticalCenter: parent.verticalCenter
        x: -(root.follow ? (root.follow.offset ?? 0) : root.offset)
        width: Tokens.instant ? root.width : implicitWidth
        elide: Tokens.instant ? Text.ElideRight : Text.ElideNone
    }

    SequentialAnimation {
        id: loop
        loops: Animation.Infinite
        PauseAnimation { duration: Tokens.motion.marqueeHold }
        NumberAnimation {
            target: root
            property: "offset"
            from: 0
            to: root.distance
            duration: Math.round(root.distance * 1000 / (Tokens.motion.marqueeSpeed * Math.max(0.01, root.s)))
        }
        PauseAnimation { duration: Tokens.motion.marqueeHold }
        PropertyAction { target: root; property: "offset"; value: 0 }
    }
}
