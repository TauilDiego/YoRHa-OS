pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"

// Tab of the header bar (header-button): square icon + label on a 47 px band.
//   state: "normal" | "hovered" | "selected" | "dimmed". The parent drives it, usually from
//   `hovered` and its own selection; the button never changes its own state.
//   On entering hovered/selected the ink sweeps left→right (Tokens.motion.highlight).
//   With selected + reachRule, the ink grows down to `ruleY` (px from the button's top) to
//   merge with the rule under the bar; the button's own height does not change.
// The Selector hangs to the LEFT, outside the box, at x = -selectorRoom: the parent must keep
// `selectorRoom` px free before the button (e.g. Row spacing or a leading spacer).
Item {
    id: root

    property real s: 1
    property string text
    property bool reachRule: false
    property real ruleY: 0
    property real fixedWidth: 0                  // game px; 0 = fit the label
    property string selectorTone: ""             // "dark" / "light"; "" = light when selected
    property bool showSelector: true             // false: no Pod cursor (e.g. the HUD's tabs)

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
    readonly property int bandH: Tokens.px(Tokens.space.tabH, s)
    readonly property int pad: Tokens.px((Tokens.space.tabH - Tokens.space.square) / 2, s)
    readonly property int gap: Tokens.px(Tokens.space.tabIconGap, s)

    implicitHeight: bandH
    implicitWidth: fixedWidth > 0 ? Tokens.px(fixedWidth, s)
                                  : pad + Tokens.px(Tokens.space.square, s) + gap + Math.ceil(dark.labelWidth) + pad

    // Ink sweep: 0 → 1 when entering an inked state, instant on the way out or when frozen.
    property real sweep: 0
    readonly property real fill: Tokens.frozen ? (inked ? 1 : 0) : sweep
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
        property color ink
        readonly property real labelWidth: label.implicitWidth
        width: root.width
        height: root.bandH
        Square {
            x: root.pad
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            color: parent.ink
        }
        Label {
            id: label
            x: root.pad + Tokens.px(Tokens.space.square, root.s) + root.gap
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            role: "headerButton"
            upper: true
            text: root.text
            color: parent.ink
        }
    }

    Rectangle {
        width: root.width
        height: root.bandH
        color: Tokens.color.lightGray
    }

    Face {
        id: dark
        ink: root.state === "dimmed" ? Tokens.color.mediumGray : Tokens.color.darkGray
    }

    Rectangle {
        width: Math.round(root.width * root.fill)
        height: root.state === "selected" && root.reachRule ? Math.max(root.bandH, Math.round(root.ruleY)) : root.bandH
        visible: width > 0
        clip: true
        color: Tokens.color.darkGray

        Face { ink: Tokens.color.lightYellow }
    }

    Selector {
        x: -root.selectorRoom
        y: Math.round((root.bandH - height) / 2)
        s: root.s
        visible: root.inked && root.showSelector
        tone: root.selectorTone || (root.state === "selected" ? "light" : "dark")
        bobbing: true
    }

    MouseArea {
        id: mouse
        width: root.width
        height: root.bandH
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor        // clickable: the hand cursor (spec 002)
        onClicked: root.clicked()
    }
}
