pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"

// List item (FR-004): square marker + label (+ optional right-aligned `trailing`) on a 48 px band.
//   state: "normal" | "hovered" | "selected" | "dimmed", driven by the parent (see `hovered`).
//   variant: "opaque" (lightGray band at rest, category lists) or "plain" (no band at rest).
//   Hovered/selected: the ink band, its rails (2 px, 5 px above and below) and its box shadow
//   sweep in from the left together.
// The parent sets the width. The Selector hangs to the left at x = -selectorRoom, outside the
// item; the parent keeps that room free.
Item {
    id: root

    property real s: 1
    property string text
    property string variant: "opaque"
    property string trailing: ""
    // spec 003: px kept free on the right for a value the parent draws (OptionRow). The label is
    // cut with an ellipsis before it, or before the trailing text, or at the band's padding.
    property real reserve: 0
    // spec 004: the trailing text's role ("small" for the picker's "● ALL" mark), and a smaller
    // content — text, square and paddings at contentScale × s — on the same band, rails, shadow and
    // kite (the picker's option rows, to fit their card).
    property string trailingRole: "listButton"
    property real contentScale: 1
    // spec 008 (the text log's rows): `lead`, a text in weight 600 before the label (who speaks,
    // at most 150 px, cut with an ellipsis); `tag`, an outline Tag before the trailing text (NEW);
    // `markColor`, the square's color (the alert square of a critical entry; default: the ink).
    // Empty, they change nothing.
    property string lead: ""
    property string tag: ""
    property color markColor: "transparent"
    readonly property real cs: s * contentScale

    readonly property bool hovered: mouse.containsMouse
    readonly property int selectorRoom: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, s)

    signal clicked()

    state: "normal"
    states: [
        State { name: "normal" },
        State { name: "hovered" },
        State { name: "selected" },
        State { name: "dimmed" }
    ]

    readonly property bool inked: state === "hovered" || state === "selected"
    readonly property int bandH: Tokens.px(Tokens.space.listItemH, s)
    readonly property int pad: Tokens.px(16, cs)         // band edge → square, and trailing → edge
    readonly property int gap: Tokens.px(16, cs)         // square → label (approved mockup)
    readonly property int rail: Tokens.line(Tokens.space.rail, s)
    readonly property int railGap: Tokens.px(Tokens.space.railGap, s)

    implicitHeight: bandH
    implicitWidth: pad + Tokens.px(Tokens.space.square, cs) + gap + Math.ceil(dark.labelWidth)
                   + (lead !== "" ? Math.ceil(dark.leadWidth) + gap : 0)
                   + (tag !== "" ? Math.ceil(dark.tagWidth) + gap : 0)
                   + (trailing !== "" ? gap + Math.ceil(dark.trailingWidth) : 0) + pad

    // Ink sweep, as in HeaderButton.
    property real sweep: 0
    readonly property real fill: Tokens.frozen ? (inked ? 1 : 0) : sweep
    readonly property int inkW: Math.round(width * fill)
    onInkedChanged: {
        sweepAnim.stop();
        if (inked && !Tokens.frozen)
            sweepAnim.start();
        else
            sweep = inked ? 1 : 0;
    }
    Component.onCompleted: sweep = inked ? 1 : 0

    NumberAnimation {
        id: sweepAnim
        target: root
        property: "sweep"
        from: 0
        to: 1
        duration: Tokens.motion.highlight
        easing.type: Easing.OutCubic
    }

    component Face: Item {
        id: face
        property color ink
        readonly property real labelWidth: label.implicitWidth
        readonly property real trailingWidth: tail.implicitWidth
        readonly property real leadWidth: leadLabel.width
        readonly property real tagWidth: tagBox.implicitWidth
        width: root.width
        height: root.bandH
        Square {
            x: root.pad
            anchors.verticalCenter: parent.verticalCenter
            s: root.cs
            color: root.markColor.a > 0 ? root.markColor : parent.ink
        }
        Label {
            id: leadLabel
            x: root.pad + Tokens.px(Tokens.space.square, root.cs) + root.gap
            width: root.lead !== "" ? Math.min(implicitWidth, Tokens.px(150, root.cs)) : 0
            visible: root.lead !== ""
            anchors.verticalCenter: parent.verticalCenter
            s: root.cs
            role: "listButton"
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": Font.DemiBold })
            text: root.lead
            elide: Text.ElideRight
            color: parent.ink
        }
        Label {
            id: label
            x: root.pad + Tokens.px(Tokens.space.square, root.cs) + root.gap + (root.lead !== "" ? leadLabel.width + root.gap : 0)
            width: Math.max(0, Math.min(implicitWidth, root.width - x - Math.max(root.pad, root.reserve)
                                                        - (root.tag !== "" ? Math.ceil(tagBox.implicitWidth) + root.gap : 0)
                                                        - (root.trailing !== "" ? root.gap + Math.ceil(tail.implicitWidth) + root.pad : 0)))
            anchors.verticalCenter: parent.verticalCenter
            s: root.cs
            role: "listButton"
            text: root.text
            elide: Text.ElideRight
            color: parent.ink
        }
        Label {
            id: tail
            anchors.right: parent.right
            anchors.rightMargin: root.pad
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailing !== ""
            s: root.cs
            role: root.trailingRole
            text: root.trailing
            color: parent.ink
        }
        Tag {
            id: tagBox
            visible: root.tag !== ""
            anchors.right: root.trailing !== "" ? tail.left : parent.right
            anchors.rightMargin: root.trailing !== "" ? root.gap : root.pad
            anchors.verticalCenter: parent.verticalCenter
            s: root.cs
            outline: true
            ink: face.ink
            text: root.tag
        }
    }

    // box shadow, under everything
    Rectangle {
        x: Tokens.px(Tokens.shadow.boxX, root.s)
        y: Tokens.px(Tokens.shadow.boxY, root.s)
        width: root.inkW
        height: root.bandH
        visible: root.inkW > 0
        color: Tokens.color.boxShadow
    }

    Rectangle {
        width: root.width
        height: root.bandH
        visible: root.variant === "opaque"
        color: Tokens.color.lightGray
    }

    Face {
        id: dark
        ink: root.state === "dimmed" ? Tokens.color.mediumGray : Tokens.color.darkGray
    }

    // rails
    Repeater {
        model: [-1, 1]
        Rectangle {
            required property int modelData
            y: modelData < 0 ? -root.railGap - root.rail : root.bandH + root.railGap
            width: root.inkW
            height: root.rail
            visible: root.inkW > 0
            color: Tokens.color.darkGray
        }
    }

    Rectangle {
        width: root.inkW
        height: root.bandH
        visible: root.inkW > 0
        clip: true
        color: Tokens.color.darkGray

        Face { ink: Tokens.color.lightYellow }
    }

    Selector {
        x: -root.selectorRoom
        y: Math.round((root.bandH - height) / 2)
        s: root.s
        shown: root.inked
        tone: root.state === "selected" ? "light" : "dark"
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor        // clickable: the hand cursor (spec 002)
        onClicked: root.clicked()
    }
}
