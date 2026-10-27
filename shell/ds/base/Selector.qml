pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."

// The Pod cursor (FR-005): a kite pointing right, with a round hole near the back, plus two
// small ink squares at its tip, one above and one below the axis. The item's right edge is
// the kite's tip; the parent leaves Tokens.space.selectorGap between it and the target.
// With `bobbing`, the whole group sways horizontally as a sine; frozen → rests at 0.
Item {
    id: root

    property real s: 1
    property string tone: "dark"                 // kite color: "dark" (ink) or "light"
    property bool bobbing: false

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

    // Horizontal sway (±amplitude, one period per cycle), in whole pixels so edges stay crisp.
    property real offset: 0
    readonly property real amplitude: Tokens.motion.bobAmplitude * s
    readonly property int period: Tokens.motion.bobPeriod
    readonly property bool swaying: bobbing && visible && !Tokens.frozen
    onSwayingChanged: if (!swaying) offset = 0

    SequentialAnimation on offset {
        running: root.swaying
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: root.amplitude; duration: root.period / 4; easing.type: Easing.OutSine }
        NumberAnimation { from: root.amplitude; to: -root.amplitude; duration: root.period / 2; easing.type: Easing.InOutSine }
        NumberAnimation { from: -root.amplitude; to: 0; duration: root.period / 4; easing.type: Easing.InSine }
    }

    Item {
        x: Math.round(root.offset)
        width: root.width
        height: root.height

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
