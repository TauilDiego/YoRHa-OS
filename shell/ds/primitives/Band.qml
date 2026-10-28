import QtQuick
import ".."

// The band (spec 008, design-system §9): the material of transmissions, the critical band and the
// OSD, after the game's tutorial band (§6). Translucent ink with a halftone of dark dots, a faint
// light hairline inside its edge (so it still reads over the dark scene), optional thin arcs, the
// urgency block on the left and a hard shadow down-right. Square corners, no blur; nothing animates:
// the halftone and the arcs are painted once per size (one Canvas), no shader.
//   arcs: [[cx, cy, r, fromDeg, toDeg], …] in game px from the band's top-left (clockwise), or [];
//   block: the 14 px block's color ("transparent" = none); shadow: the hard shadow.
// The parent sets the size; content goes on top (children of the parent, after the Band).
Item {
    id: root

    property real s: 1
    property var arcs: []
    property color block: "transparent"
    property bool shadow: true
    property real dpr: 1                         // the monitor's scale, to snap the dots and lines

    readonly property int blockW: Tokens.px(Tokens.notify.block, s)
    readonly property int shadowOff: Tokens.px(Tokens.notify.shadow, s)

    // The hard shadow, outside the band only (as CSS box-shadow: never under the translucent ink).
    Rectangle {
        visible: root.shadow
        x: root.width
        y: root.shadowOff
        width: root.shadowOff
        height: root.height
        color: Tokens.notify.bandShadow
    }
    Rectangle {
        visible: root.shadow
        x: root.shadowOff
        y: root.height
        width: root.width - root.shadowOff
        height: root.shadowOff
        color: Tokens.notify.bandShadow
    }

    Rectangle {
        anchors.fill: parent
        color: Tokens.notify.band
    }

    Canvas {
        id: paint
        anchors.fill: parent
        renderStrategy: Canvas.Immediate
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const N = Tokens.notify;
            const step = N.dotStep * root.s;
            const r = Math.max(0.5, N.dotRadius * root.s);
            ctx.fillStyle = N.bandDot;
            ctx.beginPath();
            for (let y = step / 2; y < height; y += step)
                for (let x = step / 2; x < width; x += step) {
                    ctx.moveTo(x + r, y);
                    ctx.arc(x, y, r, 0, 2 * Math.PI);
                }
            ctx.fill();
            if (root.arcs.length > 0) {
                ctx.strokeStyle = N.bandLine;
                ctx.lineWidth = Tokens.hair(N.line * root.s, root.dpr);
                ctx.beginPath();
                for (const a of root.arcs) {
                    const cx = a[0] * root.s, cy = a[1] * root.s, rad = a[2] * root.s;
                    const a0 = a[3] * Math.PI / 180, a1 = a[4] * Math.PI / 180;
                    ctx.moveTo(cx + rad * Math.cos(a0), cy + rad * Math.sin(a0));
                    ctx.arc(cx, cy, rad, a0, a1, false);
                }
                ctx.stroke();
            }
        }
    }
    onArcsChanged: paint.requestPaint()
    onSChanged: paint.requestPaint()

    // The faint hairline inside the edge.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: Tokens.hair(1, root.dpr)
        border.color: Tokens.notify.bandEdge
    }

    Rectangle {
        width: root.blockW
        height: root.height
        visible: root.block.a > 0
        color: root.block
    }
}
