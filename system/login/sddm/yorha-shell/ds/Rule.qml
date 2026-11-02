import QtQuick
import "."

// Port of shell/ds/primitives/Rule.qml for the SDDM greeter (spec 011, research R3): the same
// rules without Quickshell. The monitor's snap comes from Screen.devicePixelRatio instead of
// QsWindow/Tokens.scaleOf, and only the `crisp` dotted pattern is kept (the greeter never needs the
// Canvas one, nor the vertical strips). Keep the numbers in sync; lab/check-011 ds-sync compares them.
//   plain:  a 2 px ink line; the parent sets the width.
//   dotted: the same line with the game's pattern underneath, repeating every 77 px: a 12×4 tick
//           hanging from the line and, halfway to the next tick, a ∵ trio of round dots (centers
//           16 apart, second row 12 px lower). The line sits at the top of the item.
Item {
    id: root

    property real s: 1
    property string kind: "plain"
    property color color: Tokens.color.darkGray

    readonly property int thickness: Tokens.line(Tokens.space.rule, s)
    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    // Dotted pattern geometry (game px, measured on 1080p captures).
    readonly property real period: 77
    readonly property real tickX: -5             // tick center, relative to the period start
    readonly property real tickW: 12
    readonly property real tickH: 4
    readonly property real trioX: 33             // trio center, relative to the period start
    readonly property real trioSpread: 8         // half the distance between the top dots
    readonly property real trioRow1: 12          // top dots' center, below the line
    readonly property real trioRow2: 24          // bottom dot's center, below the line
    readonly property real dot: 6

    implicitHeight: kind === "dotted" ? Tokens.px(trioRow2 + dot / 2 + 1, s) : thickness

    Rectangle {
        width: root.width
        height: root.thickness
        color: root.color
    }

    // The pattern as scene-graph rectangles: sizes are whole physical pixels and every mark's
    // absolute position is snapped, so it stays crisp at fractional scales.
    Item {
        id: marks
        visible: root.kind === "dotted"
        anchors.fill: parent

        readonly property real d: root.dpr
        property point o: Qt.point(0, 0)        // absolute origin, for the snap
        function place(): void {
            o = mapToItem(null, 0, 0);
        }
        function ph(v: real): real {            // a game length as whole physical px
            return Math.max(1, Math.round(v * root.s * d)) / d;
        }
        function g(v: real): real {             // a logical length on the physical grid
            return Math.round(v * d) / d;
        }
        function sx(v: real): real {
            return Math.round((o.x + v) * d) / d - o.x;
        }
        function sy(v: real): real {
            return Math.round((o.y + v) * d) / d - o.y;
        }

        readonly property real dz: ph(root.dot)
        // Round dots, as in the Figma; below 4 physical px a crisp square reads as a dot anyway.
        readonly property real dotRadius: dz * d >= 4 ? dz / 2 : 0
        readonly property real tw: ph(root.tickW)
        readonly property real th: ph(root.tickH)
        readonly property real step: g(root.period * root.s)
        readonly property real tOff: g(root.tickX * root.s - tw / 2)
        readonly property real cOff: g(root.trioX * root.s - dz / 2)
        readonly property real dx: g(root.trioSpread * root.s)
        readonly property real ty: sy(root.thickness)
        readonly property real yMax: Math.floor(height * d) / d - dz
        readonly property real y1: Math.min(yMax, sy(root.thickness / 2 + root.trioRow1 * root.s - dz / 2))
        readonly property real y2: Math.min(yMax, sy(root.thickness / 2 + root.trioRow2 * root.s - dz / 2))

        Component.onCompleted: Qt.callLater(place)
        onWidthChanged: Qt.callLater(place)
        Connections {
            target: root
            function onXChanged(): void { Qt.callLater(marks.place); }
            function onYChanged(): void { Qt.callLater(marks.place); }
        }

        Repeater {
            model: marks.visible && marks.step > 0 ? Math.ceil(marks.width / marks.step) + 1 : 0

            Item {
                id: cell
                required property int index
                readonly property real x0: index * marks.step
                readonly property real tx: x0 + marks.tOff
                readonly property real cx: x0 + marks.cOff
                // Only whole marks: a sliver cut by the edge reads as a glitch.
                readonly property bool trio: cx - marks.dx >= 0 && cx + marks.dx + marks.dz <= marks.width

                Rectangle {
                    visible: cell.tx >= 0 && cell.tx + marks.tw <= marks.width
                    x: marks.sx(cell.tx); y: marks.ty
                    width: marks.tw; height: marks.th
                    color: root.color
                }
                Rectangle {
                    visible: cell.trio
                    x: marks.sx(cell.cx - marks.dx); y: marks.y1
                    width: marks.dz; height: marks.dz
                    radius: marks.dotRadius
                    color: root.color
                }
                Rectangle {
                    visible: cell.trio
                    x: marks.sx(cell.cx + marks.dx); y: marks.y1
                    width: marks.dz; height: marks.dz
                    radius: marks.dotRadius
                    color: root.color
                }
                Rectangle {
                    visible: cell.trio
                    x: marks.sx(cell.cx); y: marks.y2
                    width: marks.dz; height: marks.dz
                    radius: marks.dotRadius
                    color: root.color
                }
            }
        }
    }
}
