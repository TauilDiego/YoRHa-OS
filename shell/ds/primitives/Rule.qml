import QtQuick
import Quickshell
import ".."

// Rules (design-system §2, §6).
//   plain:    a 2 px ink line; the parent sets the width.
//   dotted:   the same line with the game's pattern underneath, repeating every 77 px:
//             a 12×4 tick hanging from the line and a ∵ trio of dots (centers 16 apart,
//             second row 12 px lower). The line sits at the top of the item.
//   vertical: the double strips at the left of tab bars and lists (3 px + 4 gap + 6 px);
//             the parent sets the height.
Item {
    id: root

    property real s: 1
    property string kind: "plain"
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
        visible: root.kind === "dotted"
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

    Row {
        visible: root.kind === "vertical"
        height: root.height
        spacing: Tokens.px(4, root.s)
        Rectangle { width: Tokens.px(3, root.s); height: parent.height; color: root.color }
        Rectangle { width: Tokens.px(6, root.s); height: parent.height; color: root.color }
    }
}
