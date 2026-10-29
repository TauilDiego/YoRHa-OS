pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "."

// Port of shell/ds/primitives/PaperDecor.qml for the SDDM greeter (spec 011, research R3), without
// Quickshell: the monitor's snap comes from Screen.devicePixelRatio. Keep the numbers in sync;
// lab/check-011 ds-sync compares the arcs, the bundles, the angle and the double gap.
// The menu background's decoration, as measured in the game (design-system §6, spec 004 US1):
// thin circle arcs, some doubled ≈7 px apart, with off-screen centers, and bundles of 2–3 short
// diagonal lines (≈42°) with staggered starts and ends, all in ink at ≈15%. No grid, no grain.
// `phase` (0–1, one cycle) makes them breathe: each arc swings a few degrees around its own
// center, each bundle slides back and forth along its direction (twice per cycle). Vector shapes,
// so nothing is rasterized up front; a sliding bundle moves by whole physical pixels.
Item {
    id: root

    property real s: 1
    property real phase: 0
    property real arcCycles: 1                      // the arcs swing once per cycle (600 s)
    property real beamCycles: 2                     // the beams slide twice per cycle (300 s)

    clip: true

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    // Layout from the approved mockup, on a 1920×1080 surface: centers and starts as fractions of
    // the surface (so other aspect ratios keep the composition); radii and lengths in game px.
    readonly property var arcs: [
        { x: -150 / 1920, y: -220 / 1080, r: 640, start: -15, sweep: 140, double: true },
        { x: 2150 / 1920, y: 1360 / 1080, r: 660, start: 165, sweep: 150, double: true },
        { x: 1520 / 1920, y: -720 / 1080, r: 1080, start: 70, sweep: 75, double: false },
        { x: 260 / 1920, y: 1620 / 1080, r: 920, start: 250, sweep: 70, double: false }
    ]
    readonly property var bundles: [
        { x: -60 / 1920, y: 30 / 1080, len: 1050, n: 3, gap: 46 },
        { x: 1120 / 1920, y: 140 / 1080, len: 1120, n: 3, gap: 52 },
        { x: 640 / 1920, y: -80 / 1080, len: 520, n: 2, gap: 14 },
        { x: 180 / 1920, y: 720 / 1080, len: 420, n: 2, gap: 14 }
    ]
    readonly property real angle: 42 * Math.PI / 180
    readonly property real dx: Math.cos(angle)
    readonly property real dy: Math.sin(angle)
    readonly property real doubleGap: 7             // game px between the two circles of a double arc
    property real swing: Tokens.wallpaper.arcAmplitude      // degrees, each way
    property real slide: Tokens.wallpaper.beamAmplitude     // game px, each way
    property color ink: Qt.rgba(Tokens.color.darkGray.r, Tokens.color.darkGray.g, Tokens.color.darkGray.b, Tokens.wallpaper.lineAlpha)
    readonly property real stroke: Tokens.hair(Tokens.line(2, s), dpr)

    function arcStart(i: int): real {
        return arcs[i].start + swing * Math.sin(2 * Math.PI * phase * arcCycles + i * 1.7);
    }
    // Second circle of a double arc; a single arc gets an empty sweep.
    function outerSweep(i: int): real {
        return arcs[i].double ? arcs[i].sweep : 0;
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.ink; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.arcs[0].x * root.width; centerY: root.arcs[0].y * root.height
                radiusX: root.arcs[0].r * root.s; radiusY: radiusX
                startAngle: root.arcStart(0); sweepAngle: root.arcs[0].sweep; moveToStart: true
            }
            PathAngleArc {
                centerX: root.arcs[0].x * root.width; centerY: root.arcs[0].y * root.height
                radiusX: (root.arcs[0].r + root.doubleGap) * root.s; radiusY: radiusX
                startAngle: root.arcStart(0); sweepAngle: root.outerSweep(0); moveToStart: true
            }
        }
        ShapePath {
            strokeColor: root.ink; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.arcs[1].x * root.width; centerY: root.arcs[1].y * root.height
                radiusX: root.arcs[1].r * root.s; radiusY: radiusX
                startAngle: root.arcStart(1); sweepAngle: root.arcs[1].sweep; moveToStart: true
            }
            PathAngleArc {
                centerX: root.arcs[1].x * root.width; centerY: root.arcs[1].y * root.height
                radiusX: (root.arcs[1].r + root.doubleGap) * root.s; radiusY: radiusX
                startAngle: root.arcStart(1); sweepAngle: root.outerSweep(1); moveToStart: true
            }
        }
        ShapePath {
            strokeColor: root.ink; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.arcs[2].x * root.width; centerY: root.arcs[2].y * root.height
                radiusX: root.arcs[2].r * root.s; radiusY: radiusX
                startAngle: root.arcStart(2); sweepAngle: root.arcs[2].sweep; moveToStart: true
            }
        }
        ShapePath {
            strokeColor: root.ink; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.arcs[3].x * root.width; centerY: root.arcs[3].y * root.height
                radiusX: root.arcs[3].r * root.s; radiusY: radiusX
                startAngle: root.arcStart(3); sweepAngle: root.arcs[3].sweep; moveToStart: true
            }
        }
    }

    // One shape per bundle, so each slides on its own.
    Repeater {
        model: root.bundles

        Shape {
            id: bundle
            required property var modelData
            required property int index
            readonly property real drift: root.slide * root.s * Math.sin(2 * Math.PI * root.phase * root.beamCycles + index * 2.1)
            // Line j starts staggered along the bundle and is shorter; a missing third line is empty.
            function from(j: int): point {
                const b = bundle.modelData, s = root.s, g = b.gap * j, st = 34 * j;
                return Qt.point(b.x * root.width + (-root.dy * g + root.dx * st) * s,
                                b.y * root.height + (root.dx * g + root.dy * st) * s);
            }
            function to(j: int): point {
                const b = bundle.modelData, p = bundle.from(j), len = j < b.n ? (b.len - 60 * j) * root.s : 0;
                return Qt.point(p.x + root.dx * len, p.y + root.dy * len);
            }

            width: root.width
            height: root.height
            x: Tokens.snap(drift * root.dx, root.dpr)
            y: Tokens.snap(drift * root.dy, root.dpr)
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: root.ink; strokeWidth: root.stroke; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                PathMove { x: bundle.from(0).x; y: bundle.from(0).y }
                PathLine { x: bundle.to(0).x; y: bundle.to(0).y }
                PathMove { x: bundle.from(1).x; y: bundle.from(1).y }
                PathLine { x: bundle.to(1).x; y: bundle.to(1).y }
                PathMove { x: bundle.from(2).x; y: bundle.from(2).y }
                PathLine { x: bundle.to(2).x; y: bundle.to(2).y }
            }
        }
    }
}
