pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import ".."
import "../primitives"

// List item (FR-004): square marker + label (+ optional right-aligned `trailing`) on a 48 px band.
//   state: "normal" | "hovered" | "selected" | "dimmed", driven by the parent (see `hovered`).
//   variant: "opaque" (lightGray band at rest, category lists) or "plain" (no band at rest).
//   Hovered/selected: the ink band, its rails (2 px, 5 px above and below) and its box shadow
//   sweep in from the left together.
// The parent sets the width. The Selector hangs to the left at x = -selectorRoom, outside the
// item; the parent keeps that room free.
// spec 013 (front A), the game's motion (Tokens.motion, research R1):
//   selection (FR-001) the ink sweeps in over selectIn (OutQuart) from where it is, and folds back
//             over selectOut (InOutQuad) when the row loses it; the light copy of the text shows
//             only where the ink is (research R3);
//   pulse     (FR-002) the `live` row (the cursor's in the column with the focus, "hovered" by
//             default) brightens its ink band by pulseLight in a trapezoid, every motion.pulse,
//             starting pulseDelay after it gets the cursor;
//   enter     (FR-005) enter(delay, kiteAt) hides the row, wipes it in from the left after `delay`
//             ms (all but the kite) and types its label (labelCps; titleCps on the cursor's row);
//             with kiteAt ≥ 0 the kite slides in at that time (a menu assembling). It returns when
//             the row is complete (ms from now); complete() ends it at once;
//   leave     (FR-008) leave(): the live row's ink stretches ×leaveStretch and everything fades in
//             motion.leave; another row just fades in leaveOthers. restore() undoes it.
// The label is a ScrollingLabel (FR-012): a text that doesn't fit scrolls (the light copy follows
// the dark one), and is cut with an ellipsis with Tokens.instant.
// With Tokens.instant all of it is the final state at once (FR-016).
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
    // spec 013, front C (the choice pop-up): the parent draws the marker (a mark box) and/or the
    // kite (mirrored, on the right) itself.
    property bool showMark: true
    property bool showSelector: true

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
    // The window's monitor decides the hairlines (ceil(N × scale) physical px, Tokens.vline).
    // QsWindow.window is typed QObject, so go through a `var` (as Rule does).
    readonly property var window: QsWindow.window
    readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")
    // The rails: whole physical px (audit D-13: at 1.25 they came out 2 px over the band, 3 under).
    readonly property real rail: Tokens.vline(Tokens.line(Tokens.space.rail, s), dpr)
    readonly property int railGap: Tokens.px(Tokens.space.railGap, s)

    implicitHeight: bandH
    implicitWidth: pad + Tokens.px(Tokens.space.square, cs) + gap + Math.ceil(dark.labelWidth)
                   + (lead !== "" ? Math.ceil(dark.leadWidth) + gap : 0)
                   + (tag !== "" ? Math.ceil(dark.tagWidth) + gap : 0)
                   + (trailing !== "" ? gap + Math.ceil(dark.trailingWidth) : 0) + pad

    // spec 013 (FR-001): the ink sweeps in, and folds back when the row loses it.
    property real sweep: 0
    readonly property real fill: Tokens.instant ? (inked ? 1 : 0) : sweep
    readonly property int inkW: Math.round(width * fill)
    onInkedChanged: {
        sweepIn.stop();
        sweepOut.stop();
        if (Tokens.instant)
            sweep = inked ? 1 : 0;
        else if (inked)
            sweepIn.start();
        else
            sweepOut.start();
    }
    Component.onCompleted: sweep = inked ? 1 : 0

    NumberAnimation {
        id: sweepIn
        target: root
        property: "sweep"
        to: 1
        duration: Tokens.motion.selectIn
        easing.type: Easing.OutQuart
    }
    NumberAnimation {
        id: sweepOut
        target: root
        property: "sweep"
        to: 0
        duration: Tokens.motion.selectOut
        easing.type: Easing.InOutQuad
    }

    // spec 013 (FR-002): the pulse, only while the row is shown.
    property bool live: state === "hovered"
    readonly property bool pulsing: live && inked && visible && !Tokens.instant
    // One clock per cycle (a single looping animation keeps the period exact), the trapezoid from it.
    property real pulseT: 0
    readonly property real pulseLevel: pulsing ? Tokens.pulseAt(pulseT) : 0
    readonly property color pulseInk: Qt.rgba(Math.min(1, Tokens.color.darkGray.r * (1 + Tokens.motion.pulseLight)),
                                              Math.min(1, Tokens.color.darkGray.g * (1 + Tokens.motion.pulseLight)),
                                              Math.min(1, Tokens.color.darkGray.b * (1 + Tokens.motion.pulseLight)), 1)
    onPulsingChanged: {
        pulseAnim.stop();
        pulseT = 0;
        if (pulsing)
            pulseAnim.start();
    }
    SequentialAnimation {
        id: pulseAnim
        PauseAnimation { duration: Tokens.motion.pulseDelay }
        NumberAnimation {
            target: root
            property: "pulseT"
            from: 0
            to: Tokens.motion.pulse
            duration: Tokens.motion.pulse
            loops: Animation.Infinite
        }
    }

    // spec 013 (FR-005): the cascade. `reveal` wipes the row in; `typed` is how many characters of
    // the label show (< 0: all), the last one followed by a letter drawn from the label itself.
    readonly property string motionRow: "item"
    property real reveal: 1
    property real typed: -1
    property int typedCount: -1
    property string tipLetter: ""
    readonly property var chars: Array.from(text)
    readonly property string shownText: typedCount < 0 ? text : chars.slice(0, typedCount).join("") + tipLetter
    onTypedChanged: {
        const n = typed < 0 ? -1 : Math.floor(typed);
        if (n === typedCount)
            return;
        typedCount = n;
        const pool = n >= 0 && n < chars.length ? chars.filter(c => c.trim() !== "") : [];
        tipLetter = pool.length > 0 ? pool[Math.floor(Math.random() * pool.length)] : "";
    }

    function enter(delay: int, kiteAt: int): int {
        enterAnim.stop();
        restore();
        if (kiteAt >= 0)
            selector.slideIn(kiteAt);
        if (Tokens.instant) {
            complete();
            return 0;
        }
        const cps = inked ? Tokens.motion.titleCps : Tokens.motion.labelCps;
        revealPause.duration = Math.max(0, delay);
        typePause.duration = Math.max(0, delay) + Tokens.motion.cascadeType;
        typeAnim.to = chars.length;
        typeAnim.duration = Math.round(chars.length * 1000 / cps);
        reveal = 0;
        typed = 0;
        enterAnim.start();
        return Math.max(revealPause.duration + Tokens.motion.cascadeWipe, typePause.duration + typeAnim.duration);
    }
    function complete(): void {
        enterAnim.stop();
        restore();
        reveal = 1;
        typed = -1;
    }

    ParallelAnimation {
        id: enterAnim
        SequentialAnimation {
            PauseAnimation { id: revealPause }
            NumberAnimation {
                target: root
                property: "reveal"
                from: 0
                to: 1
                duration: Tokens.motion.cascadeWipe
                easing.type: Easing.OutQuart
            }
        }
        SequentialAnimation {
            PauseAnimation { id: typePause }
            NumberAnimation {
                id: typeAnim
                target: root
                property: "typed"
                from: 0
            }
            PropertyAction { target: root; property: "typed"; value: -1 }
        }
    }

    // spec 013 (FR-008): leaving the menu. `stretch` widens the ink band; `bandLevel` fades it and
    // its shadow (InQuart, with the stretch), `textLevel` the texts and the rails (linear).
    property real stretch: 1
    property real bandLevel: 1
    property real textLevel: 1
    function leave(): void {
        complete();
        if (Tokens.instant)
            return;
        if (live && inked)
            leaveLive.start();
        else
            leaveOther.start();
    }
    function restore(): void {
        leaveLive.stop();
        leaveOther.stop();
        stretch = 1;
        bandLevel = 1;
        textLevel = 1;
    }
    ParallelAnimation {
        id: leaveLive
        NumberAnimation { target: root; property: "stretch"; to: Tokens.motion.leaveStretch; duration: Tokens.motion.leave; easing.type: Easing.InQuart }
        NumberAnimation { target: root; property: "bandLevel"; to: 0; duration: Tokens.motion.leave; easing.type: Easing.InQuart }
        NumberAnimation { target: root; property: "textLevel"; to: 0; duration: Tokens.motion.leave }
    }
    ParallelAnimation {
        id: leaveOther
        NumberAnimation { target: root; property: "bandLevel"; to: 0; duration: Tokens.motion.leaveOthers }
        NumberAnimation { target: root; property: "textLevel"; to: 0; duration: Tokens.motion.leaveOthers }
    }

    // spec 013 (E1): the kite's entry while a menu assembles (the cursor's Selector).
    function holdKite(): void {
        selector.hold();
    }

    component Face: Item {
        id: face
        property color ink
        property var leader: null                // spec 013: the ScrollingLabel to scroll with
        readonly property Item scroller: label
        readonly property real labelWidth: label.implicitWidth
        readonly property real trailingWidth: tail.implicitWidth
        readonly property real leadWidth: leadLabel.width
        readonly property real tagWidth: tagBox.implicitWidth
        width: root.width
        height: root.bandH
        Square {
            x: root.pad
            visible: root.showMark
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
        // spec 013 (FR-012): a label that doesn't fit scrolls; the light copy follows the dark one.
        ScrollingLabel {
            id: label
            x: root.pad + Tokens.px(Tokens.space.square, root.cs) + root.gap + (root.lead !== "" ? leadLabel.width + root.gap : 0)
            // All the room there is, not min(implicitWidth, room): a width taken from a measure
            // made before the font's weight axis applied came out a few px short and cut the
            // last letter ("automaticalll", audit D-11). The box clips (and scrolls) only when
            // the text really overflows the room.
            width: Math.max(0, root.width - x - Math.max(root.pad, root.reserve)
                                - (root.tag !== "" ? Math.ceil(tagBox.implicitWidth) + root.gap : 0)
                                - (root.trailing !== "" ? root.gap + Math.ceil(tail.implicitWidth) + root.pad : 0))
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            s: root.cs
            role: "listButton"
            text: root.shownText
            color: parent.ink
            follow: face.leader
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

    // spec 013: everything but the kite, in a box that clips it while the row wipes in (the rails
    // stick out above and below, the shadow on the right).
    readonly property real outY: railGap + rail
    readonly property int shadowX: Tokens.px(Tokens.shadow.boxX, s)
    readonly property int bandW: Math.round(inkW * stretch)
    Item {
        id: wipe
        y: -root.outY
        width: root.reveal >= 1 ? root.width + root.shadowX : Math.round((root.width + root.shadowX) * root.reveal)
        height: root.bandH + 2 * root.outY
        visible: root.reveal > 0
        clip: root.reveal < 1

        Item {
            y: root.outY
            width: root.width
            height: root.bandH

            // box shadow, under everything
            Rectangle {
                x: Tokens.px(Tokens.shadow.boxX, root.s)
                y: Tokens.px(Tokens.shadow.boxY, root.s)
                width: root.bandW
                height: root.bandH
                visible: root.inkW > 0
                opacity: root.bandLevel
                color: Tokens.color.boxShadow
            }

            Rectangle {
                width: root.width
                height: root.bandH
                visible: root.variant === "opaque"
                opacity: root.textLevel
                color: Tokens.color.lightGray
            }

            Face {
                id: dark
                opacity: root.textLevel
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
                    opacity: root.textLevel
                    color: Tokens.color.darkGray
                }
            }

            Rectangle {
                width: root.bandW
                height: root.bandH
                visible: root.inkW > 0
                opacity: root.bandLevel
                clip: true
                color: Tokens.color.darkGray

                // spec 013 (FR-002): the pulse's light, over the ink and under the light text.
                Rectangle {
                    width: root.inkW
                    height: root.bandH
                    visible: root.pulseLevel > 0
                    opacity: root.pulseLevel
                    color: root.pulseInk
                }

                Face {
                    opacity: root.bandLevel > 0 ? Math.min(1, root.textLevel / root.bandLevel) : 0
                    ink: Tokens.color.lightYellow
                    leader: dark.scroller
                }
            }
        }
    }

    Selector {
        id: selector
        x: -root.selectorRoom
        y: Math.round((root.bandH - height) / 2)
        s: root.s
        shown: root.inked && root.showSelector
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
