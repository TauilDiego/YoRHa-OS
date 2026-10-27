import QtQuick
import Quickshell
import ".."

// Rules (design-system §2, §6).
//   plain:    a 2 px ink line; the parent sets the width.
//   dotted:   the same line with the game's pattern underneath, repeating every 77 px:
//             a 12×4 tick hanging from the line and, halfway to the next tick, a ∵ trio of
//             round dots (centers 16 apart, second row 12 px lower), as in the Figma.
//             The line sits at the top of the item.
//   vertical: the double strips at the left of tab bars and lists (3 px + 4 gap + 6 px);
//             the parent sets the height.
Item {
    id: root

    property real s: 1
    property string kind: "plain"
    property bool crisp: true                    // dotted: marks as solid squares of whole physical px (the Canvas path blurs at fractional scales)
    property color color: kind === "vertical" ? Tokens.color.lightGray : Tokens.color.darkGray

    readonly property int thickness: Tokens.line(Tokens.space.rule, s)
    // The window's monitor decides the snap. QsWindow.window is typed QObject, so go through
    // a `var` (qmllint can't see `screen` on QObject).
    readonly property var window: QsWindow.window
    readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")

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

    implicitWidth: kind === "vertical" ? Tokens.px(3 + 4 + 6, s) : 0
    implicitHeight: kind === "dotted" ? Tokens.px(trioRow2 + dot / 2 + 1, s) : kind === "plain" ? thickness : 0

    Rectangle {
        visible: root.kind !== "vertical"
        width: root.width
        height: root.thickness
        color: root.color
    }

    Canvas {
        id: pattern
        visible: root.kind === "dotted" && !root.crisp
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.fillStyle = root.color;
            // Marks snap to the monitor's physical pixels (absolute position included), so the
            // pattern stays crisp at fractional scales (SC-008).
            const d = root.dpr;
            const o = pattern.mapToItem(null, 0, 0);
            const sx = v => Tokens.snap(o.x + v, d) - o.x;
            const sy = v => Tokens.snap(o.y + v, d) - o.y;
            const rect = (x, y, w, h) => {
                const x0 = sx(x), y0 = sy(y);
                c.fillRect(x0, y0, Math.max(1 / d, sx(x + w) - x0), Math.max(1 / d, sy(y + h) - y0));
            };
            const s = root.s;
            const step = root.period * s;
            const r = Math.max(1, root.dot * s / 2);
            const tw = Math.max(2, Math.round(root.tickW * s));
            const th = Math.max(1, Math.round(root.tickH * s));
            const y1 = Math.round(root.thickness / 2 + root.trioRow1 * s);
            const y2 = Math.round(root.thickness / 2 + root.trioRow2 * s);
            // Only whole marks: a sliver cut by the edge reads as a glitch.
            for (let x0 = 0; x0 < width + step; x0 += step) {
                const tx = Math.round(x0 + root.tickX * s - tw / 2);
                if (tx >= 0 && tx + tw <= width)
                    rect(tx, root.thickness, tw, th);
                const cx = Math.round(x0 + root.trioX * s);
                const dx = Math.round(root.trioSpread * s);
                if (cx - dx - r < 0 || cx + dx + r > width)
                    continue;
                for (const [x, y] of [[cx - dx, y1], [cx + dx, y1], [cx, y2]]) {
                    if (r * d < 2.5) {          // a few physical pixels: a crisp square reads as a dot
                        rect(x - r, y - r, 2 * r, 2 * r);
                        continue;
                    }
                    c.beginPath();
                    c.arc(sx(x), sy(y), r, 0, 2 * Math.PI);
                    c.fill();
                }
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onColorChanged(): void { pattern.requestPaint(); }
            function onSChanged(): void { pattern.requestPaint(); }
            function onDprChanged(): void { pattern.requestPaint(); }
        }
    }

    // crisp: the same pattern as scene-graph rectangles. A Canvas is rasterized at logical size
    // and upscaled at fractional scales (grey edges); rectangles land on the physical grid.
    // Sizes are whole physical pixels and every mark's absolute position is snapped.
    Item {
        id: marks
        visible: root.kind === "dotted" && root.crisp
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

    Row {
        visible: root.kind === "vertical"
        height: root.height
        spacing: Tokens.px(4, root.s)
        Rectangle { width: Tokens.px(3, root.s); height: parent.height; color: root.color }
        Rectangle { width: Tokens.px(6, root.s); height: parent.height; color: root.color }
    }
}
