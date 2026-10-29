pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import ".."
import "../primitives"

// Workspace map (spec 007, WINDOWS' preview; contracts/components.md): one monitor drawn small, in
// the Tokens.space.mapW × mapH area (game px × s), letterboxed to the monitor's proportion:
//   - the monitor as paper, with the top bar's band (`bar`, logical px of the monitor) in light-gray;
//   - each window a light-gray rectangle with a 1 px dark-gray outline, at its real place and size
//     (scaled); the floating ones over the tiled ones;
//   - the `selected` window in ink (dark-gray), on top of its layer, with its title in light-yellow (small, cut);
//   - a 2 px medium-gray outline around the monitor, over everything.
// Empty (no windows): only the paper, the band and the outline.
// Every edge lands on the monitor's physical pixel grid (as the 001's rules), so the 1 px lines stay
// crisp at fractional scales.
//   monitor: { name, w, h } (logical px); windows: [{ address (or id), x, y, w, h (relative to the
//   monitor), title, focused, floating }]; selected: an address.
Item {
    id: root

    property real s: 1
    property var monitor: null
    property real bar: 0
    property var windows: []
    property string selected: ""

    // QsWindow.window is typed QObject: go through a var (as Rule does) to read its screen.
    readonly property var window: QsWindow.window
    readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")

    implicitWidth: Tokens.px(Tokens.space.mapW, s)
    implicitHeight: Tokens.px(Tokens.space.mapH, s)

    readonly property real monW: Math.max(1, Number(monitor?.w) || 1920)
    readonly property real monH: Math.max(1, Number(monitor?.h) || 1080)
    readonly property real k: Math.min(width / monW, height / monH)
    readonly property real boxX: (width - monW * k) / 2
    readonly property real boxY: (height - monH * k) / 2
    readonly property real outline: Tokens.hair(Tokens.line(2, s), dpr)
    readonly property real thin: Tokens.hair(1, dpr)

    function idOf(w: var): string {
        return String(w?.address ?? w?.id ?? "");
    }

    // Tiled first, then floating (as the compositor stacks them); in each, the selected one last.
    readonly property var ordered: (Array.isArray(windows) ? windows : []).slice().sort((a, b) => {
        const sa = idOf(a) === selected ? 1 : 0, sb = idOf(b) === selected ? 1 : 0;
        return ((a?.floating ? 1 : 0) - (b?.floating ? 1 : 0)) || (sa - sb);
    })

    // The absolute origin, for the snap to physical pixels.
    property point origin: Qt.point(0, 0)
    function place(): void {
        origin = mapToItem(null, 0, 0);
    }
    Component.onCompleted: Qt.callLater(place)
    onXChanged: Qt.callLater(place)
    onYChanged: Qt.callLater(place)
    onWidthChanged: Qt.callLater(place)
    onVisibleChanged: if (visible) Qt.callLater(place)

    function sx(v: real): real {
        return Tokens.snap(origin.x + v, dpr) - origin.x;
    }
    function sy(v: real): real {
        return Tokens.snap(origin.y + v, dpr) - origin.y;
    }
    // A rectangle of the monitor (logical px) in the item's px, snapped: { x, y, w, h }.
    function box(x: real, y: real, w: real, h: real): var {
        const x0 = sx(boxX + Math.max(0, x) * k), y0 = sy(boxY + Math.max(0, y) * k);
        const x1 = sx(boxX + Math.min(monW, x + w) * k), y1 = sy(boxY + Math.min(monH, y + h) * k);
        return { x: x0, y: y0, w: Math.max(thin, x1 - x0), h: Math.max(thin, y1 - y0) };
    }

    readonly property var screenBox: box(0, 0, monW, monH)
    readonly property var barBox: box(0, 0, monW, Math.max(0, bar))

    // The area around a monitor of another proportion.
    Rectangle {
        anchors.fill: parent
        color: Tokens.color.lightGray
    }

    Rectangle {
        x: root.screenBox.x
        y: root.screenBox.y
        width: root.screenBox.w
        height: root.screenBox.h
        color: Tokens.color.darkYellow
    }

    Rectangle {
        x: root.barBox.x
        y: root.barBox.y
        width: root.barBox.w
        height: root.bar > 0 ? root.barBox.h : 0
        visible: root.bar > 0
        color: Tokens.color.lightGray
    }

    Repeater {
        model: root.ordered

        Rectangle {
            id: win
            required property var modelData
            readonly property bool chosen: root.idOf(modelData) === root.selected && root.selected !== ""
            readonly property var r: root.box(Number(modelData?.x) || 0, Number(modelData?.y) || 0,
                                              Math.max(1, Number(modelData?.w) || 1), Math.max(1, Number(modelData?.h) || 1))
            x: r.x
            y: r.y
            width: r.w
            height: r.h
            color: chosen ? Tokens.color.darkGray : Tokens.color.lightGray
            border.width: root.thin
            border.color: Tokens.color.darkGray
            clip: true

            Label {
                x: Tokens.px(8, root.s)
                y: Tokens.px(6, root.s)
                width: Math.max(0, parent.width - 2 * x)
                visible: win.chosen && width > 0
                s: root.s
                role: "small"
                elide: Text.ElideRight
                text: String(win.modelData?.title ?? "")
                color: Tokens.color.lightYellow
            }
        }
    }

    // The monitor's outline, inside its box.
    Rectangle {
        x: root.screenBox.x
        y: root.screenBox.y
        width: root.screenBox.w
        height: root.screenBox.h
        color: "transparent"
        border.width: root.outline
        border.color: Tokens.color.mediumGray
    }
}
