pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."

// The Pod cursor (FR-005): a kite pointing right, with a round hole near the back, plus two
// small ink squares at its tip, one above and one below the axis. The item's right edge is
// the kite's tip; the parent leaves Tokens.space.selectorGap between it and the target.
// It stays still, as in the game. `shown` blinks it: hiding fades out (ease-in) in half of
// Tokens.motion.blink; showing waits that half, then fades in (ease-out). When the cursor moves,
// the old item's selector fades out while the new one waits, so it reads as one blink.
// Frozen (fixtures) or reduced motion (spec 003): no fade, it just jumps.
// spec 013 (E1): while a menu assembles, hold() hides the kite and slideIn(delay) brings it in from
// motion.kiteDx to the left, fading, over motion.kiteIn (OutQuart). The blink above is unchanged
// (FR-003, the owner's pick in the prototype).
Item {
    id: root

    property real s: 1
    property string tone: "dark"                 // kite color: "dark" (ink) or "light"
    property bool shown: false

    // Kite geometry (game px × s): back vertex, shoulder 10 px behind it, tip; hole near the back.
    readonly property real kiteW: Tokens.space.selectorW * s
    readonly property real kiteH: Tokens.space.selectorH * s
    readonly property real shoulder: 10 * s
    readonly property real holeX: 8 * s
    readonly property real holeR: Tokens.space.selectorHole * s / 2
    readonly property int dot: Math.max(2, Tokens.px(Tokens.space.selectorDot, s))
    readonly property int dotOffset: Tokens.px(Tokens.space.selectorDotOffset, s)
    readonly property real axis: height / 2

    implicitWidth: Tokens.px(Tokens.space.selectorW, s)
    implicitHeight: 2 * dotOffset + dot

    // The blink: half the time out, half in.
    readonly property int half: Tokens.instant ? 0 : Math.round(Tokens.motion.blink / 2)

    opacity: 0
    visible: opacity > 0
    states: State {
        name: "shown"
        when: root.shown
        PropertyChanges { root.opacity: 1 }
    }
    transitions: [
        Transition {
            to: "shown"
            SequentialAnimation {
                PauseAnimation { duration: root.half }
                NumberAnimation { property: "opacity"; duration: root.half; easing.type: Easing.OutSine }
            }
        },
        Transition {
            from: "shown"
            NumberAnimation { property: "opacity"; duration: root.half; easing.type: Easing.InSine }
        }
    ]

    property real intro: 1
    function hold(): void {
        introAnim.stop();
        intro = Tokens.instant ? 1 : 0;
    }
    function slideIn(delay: int): void {
        introAnim.stop();
        if (Tokens.instant) {
            intro = 1;
            return;
        }
        intro = 0;
        introPause.duration = Math.max(0, delay);
        introAnim.start();
    }
    SequentialAnimation {
        id: introAnim
        PauseAnimation { id: introPause }
        NumberAnimation {
            target: root
            property: "intro"
            from: 0
            to: 1
            duration: Tokens.motion.kiteIn
            easing.type: Easing.OutQuart
        }
    }

    Item {
        width: root.width
        height: root.height
        opacity: root.intro
        x: -Math.round((1 - root.intro) * Tokens.motion.kiteDx * root.s)

        Shape {
            width: root.kiteW
            height: root.kiteH
            y: root.axis - height / 2
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.tone === "light" ? Tokens.color.lightYellow : Tokens.color.darkGray
                fillRule: ShapePath.OddEvenFill
                strokeWidth: -1
                startX: 0
                startY: root.kiteH / 2
                PathLine { x: root.shoulder; y: 0 }
                PathLine { x: root.kiteW; y: root.kiteH / 2 }
                PathLine { x: root.shoulder; y: root.kiteH }
                PathLine { x: 0; y: root.kiteH / 2 }
                // the hole: a second subpath, cut out by the odd-even rule
                PathMove { x: root.holeX + root.holeR; y: root.kiteH / 2 }
                PathArc { x: root.holeX - root.holeR; y: root.kiteH / 2; radiusX: root.holeR; radiusY: root.holeR }
                PathArc { x: root.holeX + root.holeR; y: root.kiteH / 2; radiusX: root.holeR; radiusY: root.holeR }
            }
        }

        // The two squares are always ink, right-aligned with the kite's tip.
        Repeater {
            model: [-1, 1]
            Rectangle {
                required property int modelData
                x: Math.round(root.kiteW) - width
                y: Math.round(root.axis + modelData * root.dotOffset - width / 2)
                width: root.dot
                height: root.dot
                color: Tokens.color.darkGray
            }
        }
    }
}
