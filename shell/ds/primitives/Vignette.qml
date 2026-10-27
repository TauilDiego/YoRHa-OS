import QtQuick
import ".."

// Full-screen vignette (FR-002a): an elliptical radial gradient of ink, clear in the middle,
// ≈#A6A18D at the edges and ≈#8B8877 in the corners over the paper. Put it last, over
// everything; it takes no input. `enabled: false` hides it.
Canvas {
    id: root

    property real s: 1                           // shared interface; the vignette is scale-free

    visible: enabled

    onPaint: {
        const c = getContext("2d");
        c.reset();
        const ink = Tokens.color.darkGray;
        const rgba = a => `rgba(${Math.round(ink.r * 255)},${Math.round(ink.g * 255)},${Math.round(ink.b * 255)},${a})`;
        const v = Tokens.vignette;
        // Squash a circle into the screen's ellipse: edges at t = √½, corners at t = 1.
        c.save();
        c.translate(width / 2, height / 2);
        c.scale(1, height / width);
        const g = c.createRadialGradient(0, 0, 0, 0, 0, Math.SQRT1_2 * width);
        g.addColorStop(0, rgba(0));
        g.addColorStop(v.start, rgba(0));
        g.addColorStop(Math.SQRT1_2, rgba(v.edgeAlpha));
        g.addColorStop(1, rgba(v.cornerAlpha));
        c.fillStyle = g;
        c.fillRect(-width / 2, -width / 2, width, width);
        c.restore();
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
}
