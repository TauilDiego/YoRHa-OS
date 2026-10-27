pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"

// Tab of the header bar (header-button): square icon + label on a 47 px band.
//   state: "normal" | "hovered" | "selected" | "dimmed". The parent drives it, usually from
//   `hovered` and its own selection; the button never changes its own state.
//   On entering hovered/selected the ink sweeps left→right (Tokens.motion.highlight).
//   With selected + reachRule, a stem of ink grows down to `ruleY` (px from the button's top)
//   to touch the rule under the bar, right after the sweep (Tokens.motion.touch), and retracts
//   when the tab is deselected (Tokens.motion.untouch). The button's own height does not change.
// Tabs have no Selector (the owner's call): only list items carry the Pod cursor.
// `tone` (spec 004 US6): the top bar's tone, 0 paper → 1 light (plate, ink and the selected ink).
Item {
    id: root

    property real s: 1
    property real tone: 0
    property string text
    property bool reachRule: false
    property real ruleY: 0
    property real fixedWidth: 0                  // game px; 0 = fit the label

    readonly property bool hovered: mouse.containsMouse

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
    Component.onCompleted: {
        sweep = inked ? 1 : 0;
        reach = touching ? 1 : 0;
    }

    // Stem: 0 → 1 down to the rule once selected, after what is left of the sweep.
    property real reach: 0
    readonly property bool touching: state === "selected" && reachRule
    onTouchingChanged: {
        touchAnim.stop();
        untouchAnim.stop();
        if (Tokens.frozen)
            reach = touching ? 1 : 0;
        else if (touching) {
            touchDelay.duration = Math.round(Tokens.motion.highlight * (1 - sweep));
            touchAnim.start();
        } else
            untouchAnim.start();
    }

    SequentialAnimation {
        id: touchAnim
        PauseAnimation {
            id: touchDelay
        }
        NumberAnimation {
            target: root
            property: "reach"
            to: 1
            duration: Tokens.motion.touch
            easing.type: Easing.OutCubic
        }
    }
    NumberAnimation {
        id: untouchAnim
        target: root
        property: "reach"
        to: 0
        duration: Tokens.motion.untouch
        easing.type: Easing.InCubic
    }

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

    // The resting face, hidden once the ink covers it all: the ink is clipped, and at a half
    // physical pixel the clip and this rectangle can round apart (a 1 px light sliver).
    Rectangle {
        width: root.width
        height: root.bandH
        visible: root.fill < 1
        color: Tokens.hudColor("rest", root.tone)
    }

    Face {
        id: dark
        visible: root.fill < 1
        ink: Tokens.hudColor(root.state === "dimmed" ? "ink2" : "ink", root.tone)
    }

    // The stem, from the band's bottom to the rule. While inked it is part of the ink itself:
    // one rectangle, so at fractional scales its edges round together with the band's (two
    // rectangles at a half physical pixel can round apart and leave a 1 px burr). Only the
    // retracting stem of a deselected tab, with no ink above it, is drawn on its own.
    readonly property int stemH: Math.round(Math.max(0, ruleY - bandH) * reach)
    Rectangle {
        y: root.bandH
        width: root.width
        height: root.stemH
        visible: !root.inked && height > 0
        color: Tokens.hudColor("sel", root.tone)
    }

    Rectangle {
        width: Math.round(root.width * root.fill)
        height: root.bandH + root.stemH
        visible: width > 0
        clip: true
        color: Tokens.hudColor("sel", root.tone)

        Face { ink: Tokens.hudColor("selInk", root.tone) }
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
