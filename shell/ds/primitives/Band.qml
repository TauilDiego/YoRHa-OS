import QtQuick
import QtQuick.Shapes
import ".."

// The band (spec 008, design-system §9): the material of transmissions, the critical band and the
// OSD, after the game's tutorial band (§6). Translucent ink with a halftone of dark dots, a faint
// light hairline inside its edge (so it still reads over the dark scene), optional thin arcs, the
// urgency block on the left and a hard shadow down-right. Square corners, no blur; nothing animates:
// the halftone is one tiled dot image and the arcs one static Shape, no shader.
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

    // The halftone: one dot tile (an SVG, drawn by Qt at the screen's resolution), tiled. Painting
    // every dot in a Canvas took over a second for a wide band on the lab's software renderer.
    readonly property real dotStep: Tokens.notify.dotStep * s
    Image {
        anchors.fill: parent
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        smooth: true
        cache: true
        sourceSize: Qt.size(root.dotStep, root.dotStep)
        source: root.dotTile
    }
    readonly property string dotTile: {
        const N = Tokens.notify;
        const c = N.bandDot;
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${N.dotStep}" height="${N.dotStep}">`
            + `<circle cx="${N.dotStep / 2}" cy="${N.dotStep / 2}" r="${N.dotRadius}" `
            + `fill="rgb(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)})" fill-opacity="${c.a}"/></svg>`;
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
    }

    // The thin arcs: one static Shape (an SVG path of arcs), clipped to the band.
    Item {
        anchors.fill: parent
        clip: true
        visible: root.arcs.length > 0

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Tokens.notify.bandLine
                strokeWidth: Tokens.hair(Tokens.notify.line * root.s, root.dpr)
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                PathSvg {
                    path: root.arcPath
                }
            }
        }
    }
    // [[cx, cy, r, fromDeg, toDeg], …] (clockwise, game px) → "M … A …" in this band's px.
    readonly property string arcPath: {
        let d = "";
        for (const a of arcs) {
            const cx = a[0] * s, cy = a[1] * s, r = a[2] * s;
            const a0 = a[3] * Math.PI / 180, a1 = a[4] * Math.PI / 180;
            const sweep = ((a[4] - a[3]) % 360 + 360) % 360;
            d += `M ${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} `
               + `A ${r} ${r} 0 ${sweep > 180 ? 1 : 0} 1 ${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)} `;
        }
        return d;
    }

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
