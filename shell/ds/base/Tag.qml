import QtQuick
import Quickshell
import ".."
import "../primitives"

// A small tag (spec 008): CRITICAL (light text on `alert`, next to the speaker; FR-010) or NEW (an
// outline of 1.5 px in the text's color, on a log row while the log is open; spec 015: above the
// SYSTEM tab and on the Updates row).
//   fill: the tag's ground ("transparent" for an outline tag); outline: draw the outline.
//
// Laid out in whole physical pixels, at any scale:
// - the outline is a vector hairline, ceil(1.5 × s × dpr) px (Tokens.vline);
// - the text is centered by its ink (the glyphs' tight bounds: the cap height for all-caps text),
//   not by its line box (ascent + descent, plus the letter spacing after the last letter), so the
//   gaps between the ink and the outline are equal left/right and top/bottom;
// - the box keeps the size the line-box layout gave it (advance + side padding, type size + top
//   and bottom padding), within a physical pixel;
// - the box and the baseline sit on the monitor's physical grid (absolute position snapped).
Item {
    id: root

    property real s: 1
    property string text
    property color fill: Tokens.color.alert
    property bool outline: false
    property color ink: Tokens.notify.bandText
    // The monitor's scale. By default the window's monitor; callers that know it may set it.
    // QsWindow.window is typed QObject, so go through a `var` (as in Rule).
    readonly property var window: QsWindow.window
    property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")

    // --- layout, in physical pixels ---------------------------------------------------------------
    readonly property real d: dpr > 0 ? dpr : 1
    readonly property int line: outline ? Math.round(Tokens.vline(1.5 * s, d) * d) : 0
    // The ink's tight bounds in physical px, relative to the pen origin on the baseline (y < 0
    // above it). Qt gives them in whole pixels, rounded outwards. At scale 1 the glyphs are hinted
    // and those whole pixels are what is drawn, so the font is measured as it is; scaled, Qt draws
    // them unhinted, so they are measured on the font at 8× the physical size and scaled back (the
    // rounding stays under 1/8 px).
    readonly property real physSize: label.font.pixelSize * d
    readonly property int metricsSize: Math.max(1, Math.round((d === 1 ? 1 : 8) * physSize))
    readonly property real k: physSize / metricsSize
    readonly property rect inkRect: Qt.rect(metrics.tightBoundingRect.x * k, metrics.tightBoundingRect.y * k,
                                            metrics.tightBoundingRect.width * k, metrics.tightBoundingRect.height * k)
    readonly property int inkW: Math.max(1, Math.round(inkRect.width))
    readonly property int inkH: Math.max(1, Math.round(inkRect.height))
    // The size the line-box layout had.
    readonly property real lineBoxW: (label.implicitWidth + 2 * Tokens.px(outline ? 4 : 8, s)) * d
    readonly property real lineBoxH: Math.round(label.size + Tokens.px(outline ? 5 : 9, s)) * d
    // The same gap on both sides of the ink, between it and the outline (or the fill's edge).
    readonly property int gapX: Math.max(1, Math.round((lineBoxW - inkW) / 2) - line)
    readonly property int gapY: Math.max(1, Math.round((lineBoxH - inkH) / 2) - line)
    readonly property int boxW: inkW + 2 * (gapX + line)
    readonly property int boxH: inkH + 2 * (gapY + line)
    // The pen origin, from the box's top-left corner: the ink's center on the box's center.
    readonly property int penX: Math.round(boxW / 2 - inkRect.x - inkRect.width / 2)
    readonly property int baseY: Math.round(boxH / 2 - inkRect.y - inkRect.height / 2)

    implicitWidth: boxW / d
    implicitHeight: boxH / d

    // The absolute origin, to put the box on the physical grid.
    property point origin: Qt.point(0, 0)
    function place(): void {
        origin = mapToItem(null, 0, 0);
    }
    readonly property real gx: Math.round(origin.x * d) / d - origin.x
    readonly property real gy: Math.round(origin.y * d) / d - origin.y

    Component.onCompleted: Qt.callLater(place)
    onXChanged: Qt.callLater(place)
    onYChanged: Qt.callLater(place)
    onVisibleChanged: Qt.callLater(place)
    onWindowChanged: Qt.callLater(place)
    onDChanged: Qt.callLater(place)

    // The label's font at the physical size.
    TextMetrics {
        id: metrics
        font.family: label.font.family
        font.weight: label.font.weight
        font.variableAxes: label.font.variableAxes
        font.letterSpacing: label.font.letterSpacing * root.d / root.k
        font.pixelSize: root.metricsSize
        text: label.text
    }

    Rectangle {
        x: root.gx
        y: root.gy
        width: root.boxW / root.d
        height: root.boxH / root.d
        color: root.outline ? "transparent" : root.fill
        border.width: root.line / root.d
        border.color: root.ink
    }

    Label {
        id: label
        x: root.gx + root.penX / root.d
        y: root.gy + root.baseY / root.d - baselineOffset
        s: root.s
        role: "bandTag"
        font.pixelSize: root.outline ? Math.max(1, Tokens.px(12, root.s)) : size
        text: root.text
        color: root.ink
    }
}
