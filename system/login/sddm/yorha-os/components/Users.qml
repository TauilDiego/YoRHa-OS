pragma ComponentBehavior: Bound

import QtQuick
import "../ds"

// The user list (spec 011 FR-004, FR-005, FR-015; mockup v3.2 ".users"): a USERS label, then the
// listable users and "Other user…" at the end, as list items with the ink sweep and the kite.
// More than `rows` items scroll in whole rows inside a window that keeps room for the kite, the rails
// and the shadow, with a thin scroll bar to the right and the "n / total" count on the label.
// The parent owns the selection (`current`; users.length is "Other user…") and moves it with the
// keys; a click emits picked(index).
Item {
    id: root

    property real s: 1
    property var users: []                       // [{ name, label }]
    property int current: 0
    property bool interactive: true

    signal picked(int index)

    readonly property int rows: 10               // rows shown before the list scrolls
    readonly property int count: users.length + 1
    readonly property int shown: Math.min(rows, count)
    readonly property int band: Tokens.px(Tokens.space.listItemH, s)
    readonly property int gap: Tokens.px(Tokens.space.listItemGap, s)
    readonly property int step: band + gap
    readonly property int listH: shown * step - gap
    // The window's padding (mockup ".win"): the kite on the left, the rails above and below, the
    // shadow on the right.
    readonly property int padL: Tokens.px(46.08, s)
    readonly property int padR: Tokens.px(7.68, s)
    readonly property int padV: Tokens.px(11.52, s)

    property int topRow: 0
    onCurrentChanged: follow()
    onCountChanged: follow()
    function follow(): void {
        let t = Math.max(0, Math.min(topRow, count - shown));
        if (current < t)
            t = current;
        if (current >= t + shown)
            t = current - shown + 1;
        topRow = t;
    }

    implicitWidth: Tokens.px(422.4, s)
    implicitHeight: win.y + listH

    Label {
        id: label
        s: root.s
        size: 16.32
        spacing: 3.84
        weight: Font.Normal
        upper: true
        color: Tokens.color.mediumGray
        text: "Users"
        height: Tokens.px(16.32 * 1.55, root.s)
        verticalAlignment: Text.AlignVCenter
    }
    Label {
        anchors.right: parent.right
        anchors.verticalCenter: label.verticalCenter
        visible: root.count > root.rows
        s: root.s
        size: 16.32
        spacing: 1.92
        weight: Font.Normal
        color: Tokens.color.mediumGray
        font.features: ({ "tnum": 1 })
        text: (root.current + 1) + " / " + root.count
    }

    // The list's window: clipped, in whole rows.
    Item {
        id: win
        x: -root.padL
        y: label.height + Tokens.px(10.56, root.s) - root.padV
        width: root.width + root.padL + root.padR
        height: root.listH + 2 * root.padV
        clip: true

        Column {
            id: list
            x: root.padL
            y: root.padV - root.topRow * root.step
            width: root.width
            spacing: root.gap
            Behavior on y {
                enabled: !Tokens.instant
                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
            }

            Repeater {
                model: root.count

                ListItem {
                    required property int index
                    width: list.width
                    s: root.s
                    text: index < root.users.length ? root.users[index].label : "Other user…"
                    selected: index === root.current
                    interactive: root.interactive
                    rest: Qt.rgba(215 / 255, 209 / 255, 179 / 255, 0.55)
                    onClicked: root.picked(index)
                }
            }
        }
    }

    // The scroll bar: a thin track 21 px right of the list, the thumb in ink.
    Rectangle {
        visible: root.count > root.rows
        x: root.width + Tokens.px(21.12, root.s) - width
        y: win.y + root.padV
        width: Math.max(1, Tokens.px(4.03, root.s))
        height: root.listH
        color: Qt.rgba(78 / 255, 75 / 255, 66 / 255, 0.2)

        Rectangle {
            width: parent.width
            height: Math.round(parent.height * root.shown / root.count)
            y: Math.round(parent.height * root.topRow / root.count)
            color: Tokens.color.darkGray
            Behavior on y {
                enabled: !Tokens.instant
                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
            }
        }
    }
}
