import QtQuick
import Quickshell
import ".."

// The paper: darkYellow with a faint ink grid. Drawn once per size change; the lines sit on the
// physical pixel grid of the window's monitor, so they stay crisp at fractional scales (SC-008).
Rectangle {
    id: root

    property real s: 1
    property real step: Tokens.space.gridStep      // game px

    readonly property int pitch: Math.max(2, Tokens.px(step, s))
    // The window's monitor decides the snap. QsWindow.window is typed QObject, so go through
    // a `var` (qmllint can't see `screen` on QObject).
    readonly property var window: QsWindow.window
    readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")

    color: Tokens.color.darkYellow

    Canvas {
        id: grid
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.fillStyle = Tokens.color.grid;
            const d = root.dpr;
            const o = grid.mapToItem(null, 0, 0);       // absolute offset, for the snap
            const w = Tokens.hair(Tokens.line(1, root.s), d);
            for (let x = 0; x < width; x += root.pitch)
                c.fillRect(Tokens.snap(o.x + x, d) - o.x, 0, w, height);
            for (let y = 0; y < height; y += root.pitch)
                c.fillRect(0, Tokens.snap(o.y + y, d) - o.y, width, w);
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onPitchChanged(): void { grid.requestPaint(); }
            function onDprChanged(): void { grid.requestPaint(); }
        }
    }
}
