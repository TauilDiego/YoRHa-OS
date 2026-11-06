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
// `high` (004 acabamento): the bar's High contrast (Tokens.hudPaperHigh over paper).
// spec 013 (FR-002): with `pulse`, a selected tab's plate brightens by motion.pulseLight in the
// game's trapezoid, every motion.pulse (the pause menu's open tab; the top bar never sets it).
// spec 015 (contracts/sinal.md): `tag`, an outline Tag (NEW) above the tab, in the resting ink (a
// tab's label fills its band, so the tag goes above it); "" = none. Placed by TagAbove's rule:
// railGap game px over the tab's top edge, in whole physical px, 2 game px in from its right edge
// (`tagAlign` "right") or centered over it ("center"). It takes no room in the bar's layout.
Item {
    id: root

    property real s: 1
    property real tone: 0
    property bool high: false
    property string text
    property bool reachRule: false
    property real ruleY: 0
    property real fixedWidth: 0                  // game px; 0 = fit the label
    property bool pulse: false                   // spec 013
    property string tag: ""                      // spec 015
    property string tagAlign: "right"            // spec 015: "right" | "center" (TagAbove.align)
    readonly property alias tagItem: tagBox      // for tests: where the tag landed

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

    // Ink sweep: 0 → 1 when entering an inked state, instant on the way out, when frozen or with
    // reduced motion (Tokens.instant; spec 007 FR-030).
    property real sweep: 0
    readonly property real fill: Tokens.instant ? (inked ? 1 : 0) : sweep
    onInkedChanged: {
        sweepAnim.stop();
        if (inked && !Tokens.instant)
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
        if (Tokens.instant)
            reach = touching ? 1 : 0;
        else if (touching) {
            touchDelay.duration = Math.round(Tokens.motion.highlight * (1 - sweep));
            touchAnim.start();
        } else
            untouchAnim.start();
    }

    // spec 013 (FR-002): the open tab breathes.
    readonly property bool pulsing: pulse && state === "selected" && visible && !Tokens.instant
    property real pulseT: 0
    readonly property real pulseLevel: pulsing ? Tokens.pulseAt(pulseT) : 0
    onPulsingChanged: {
        pulseAnim.stop();
        pulseT = 0;
        if (pulsing)
            pulseAnim.start();
    }
    NumberAnimation {
        id: pulseAnim
        target: root
        property: "pulseT"
        from: 0
        to: Tokens.motion.pulse
        duration: Tokens.motion.pulse
        loops: Animation.Infinite
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

    TagAbove {
        id: tagBox
        s: root.s
        align: root.tagAlign
        ink: Tokens.hudColorAt("ink", root.tone, root.high)
        text: root.tag
    }

    // The resting face, hidden once the ink covers it all: the ink is clipped, and at a half
    // physical pixel the clip and this rectangle can round apart (a 1 px light sliver).
    Rectangle {
        width: root.width
        height: root.bandH
        visible: root.fill < 1
        color: Tokens.hudColorAt("rest", root.tone, root.high)
    }

    Face {
        id: dark
        visible: root.fill < 1
        ink: Tokens.hudColorAt(root.state === "dimmed" ? "ink2" : "ink", root.tone, root.high)
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
        color: Tokens.hudColorAt("sel", root.tone, root.high)
    }

    Rectangle {
        width: Math.round(root.width * root.fill)
        height: root.bandH + root.stemH
        visible: width > 0
        clip: true
        color: Tokens.hudColorAt("sel", root.tone, root.high)

        // spec 013: the pulse's light, over the plate (and its stem) and under the text.
        Rectangle {
            readonly property color sel: Tokens.hudColorAt("sel", root.tone, root.high)
            readonly property real k: 1 + Tokens.motion.pulseLight
            width: parent.width
            height: parent.height
            visible: root.pulseLevel > 0
            opacity: root.pulseLevel
            color: Qt.rgba(Math.min(1, sel.r * k), Math.min(1, sel.g * k), Math.min(1, sel.b * k), sel.a)
        }

        Face { ink: Tokens.hudColorAt("selInk", root.tone, root.high) }
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
