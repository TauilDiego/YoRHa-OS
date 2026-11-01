import QtQuick
import "."

// Port of shell/ds/primitives/Vignette.qml for the SDDM greeter (spec 011, research R3); it needs
// nothing from Quickshell, so only the tokens' import changes. Keep the numbers in sync.
// Full-screen vignette (FR-002a): a radial gradient of ink on a circle of half the screen's
// diagonal, as measured in the game's menus: clear in the middle (the top and bottom centers stay
// paper), ≈#A6A18D at the side edges and ≈#8C8978 in the corners over the paper. It takes no input.
Canvas {
    id: root

    property real s: 1                           // shared interface; the vignette is scale-free
    property color tint: Tokens.color.darkGray
    property real start: Tokens.vignette.start
    property real edgeAt: Tokens.vignette.edgeAt
    property real edgeAlpha: Tokens.vignette.edgeAlpha
    property real cornerAlpha: Tokens.vignette.cornerAlpha

    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.clearRect(0, 0, width, height);        // reset() keeps the pixels: repaints would stack
        const ink = root.tint;
        const rgba = a => `rgba(${Math.round(ink.r * 255)},${Math.round(ink.g * 255)},${Math.round(ink.b * 255)},${a})`;
        const w = width, h = height;
        if (w <= 0 || h <= 0)
            return;
        const g = c.createRadialGradient(w / 2, h / 2, 0, w / 2, h / 2, Math.hypot(w, h) / 2);
        g.addColorStop(0, rgba(0));
        g.addColorStop(root.start, rgba(0));
        g.addColorStop(root.edgeAt, rgba(root.edgeAlpha));
        g.addColorStop(1, rgba(root.cornerAlpha));
        c.fillStyle = g;
        c.fillRect(0, 0, w, h);
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onTintChanged: requestPaint()
}
