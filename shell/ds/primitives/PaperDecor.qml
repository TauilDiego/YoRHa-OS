import QtQuick
import Quickshell
import ".."

// The menu background's decoration (design-system §2, FR-019/FR-020): large faint circle arcs
// with off-screen centers and bundles of thin diagonal lines going down-right at ~35°.
// Each layer is drawn once into its Canvas; `phase` (0–1, one full cycle) only moves the
// layers — the arcs drift on a small circle, the bundles slide back and forth along their
// direction — by whole physical pixels, so nothing is repainted and edges stay crisp.
Item {
    id: root

    property real s: 1
    property real phase: 0

    clip: true

    readonly property var window: QsWindow.window
    readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")

    // Layout in fractions of the surface (x of the width, y of the height); radii and lengths in
    // game px. Fixed, so every boot draws the same picture.
    readonly property var arcs: [
        { x: -0.10, y: 1.15, r: 1000 },
        { x: 1.05, y: -0.25, r: 820 },
        { x: 0.62, y: 1.55, r: 1100 },
        { x: 0.30, y: -0.55, r: 760 }
    ]
    readonly property var bundles: [
        { x: 0.18, y: 0.05, len: 700, n: 3 },
        { x: 0.55, y: 0.12, len: 900, n: 2 },
        { x: 0.72, y: 0.45, len: 650, n: 4 },
        { x: 0.05, y: 0.55, len: 800, n: 2 },
        { x: 0.40, y: 0.62, len: 600, n: 3 },
        { x: 0.85, y: 0.70, len: 500, n: 2 }
    ]
    readonly property real angle: 35 * Math.PI / 180
    readonly property real arcDrift: 60 * s         // radius of the arcs' drift circle
    readonly property real bundleSlide: 80 * s      // half the bundles' slide along their axis
    readonly property real margin: Math.ceil(Math.max(arcDrift, bundleSlide)) + 2

    function inkRgba(alpha: real): string {
        const ink = Tokens.color.darkGray;
        return `rgba(${Math.round(ink.r * 255)},${Math.round(ink.g * 255)},${Math.round(ink.b * 255)},${alpha})`;
    }

    // Whole physical pixels, so a moving layer never lands half-way between two pixels.
    function snap(v: real): real {
        return Tokens.snap(v, dpr);
    }

    Canvas {
        id: arcLayer
        width: root.width + 2 * root.margin
        height: root.height + 2 * root.margin
        x: root.snap(-root.margin + root.arcDrift * Math.cos(2 * Math.PI * root.phase))
        y: root.snap(-root.margin + root.arcDrift * Math.sin(2 * Math.PI * root.phase))
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.strokeStyle = root.inkRgba(0.10);
            c.lineWidth = Math.max(1, 2 * root.s);
            const w = root.width, h = root.height, m = root.margin;
            for (const a of root.arcs) {
                c.beginPath();
                c.arc(m + a.x * w, m + a.y * h, a.r * root.s, 0, 2 * Math.PI);
                c.stroke();
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Canvas {
        id: bundleLayer
        readonly property real slide: root.bundleSlide * Math.sin(2 * Math.PI * root.phase)
        width: root.width + 2 * root.margin
        height: root.height + 2 * root.margin
        x: root.snap(-root.margin + slide * Math.cos(root.angle))
        y: root.snap(-root.margin + slide * Math.sin(root.angle))
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.strokeStyle = root.inkRgba(0.08);
            c.lineWidth = Math.max(1, 1.5 * root.s);
            const w = root.width, h = root.height, m = root.margin, s = root.s;
            const dx = Math.cos(root.angle), dy = Math.sin(root.angle);
            const gap = 12 * s;
            for (const b of root.bundles) {
                for (let i = 0; i < b.n; i++) {
                    // parallel lines, offset perpendicular to the direction
                    const ox = m + b.x * w - dy * gap * i, oy = m + b.y * h + dx * gap * i;
                    c.beginPath();
                    c.moveTo(ox, oy);
                    c.lineTo(ox + dx * b.len * s, oy + dy * b.len * s);
                    c.stroke();
                }
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Connections {
        target: root
        function onSChanged(): void {
            arcLayer.requestPaint();
            bundleLayer.requestPaint();
        }
    }
}
