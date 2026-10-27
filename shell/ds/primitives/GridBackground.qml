import QtQuick
import ".."

// The paper: darkYellow with a faint ink grid. Drawn once per size change, lines on whole pixels.
Rectangle {
    id: root

    property real s: 1
    property real step: Tokens.space.gridStep      // game px

    readonly property int pitch: Math.max(2, Tokens.px(step, s))

    color: Tokens.color.darkYellow

    Canvas {
        id: grid
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d");
            c.reset();
            c.fillStyle = Tokens.color.grid;
            const w = Tokens.line(1, root.s);
            for (let x = 0; x < width; x += root.pitch)
                c.fillRect(x, 0, w, height);
            for (let y = 0; y < height; y += root.pitch)
                c.fillRect(0, y, width, w);
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onPitchChanged(): void { grid.requestPaint(); }
        }
    }
}
