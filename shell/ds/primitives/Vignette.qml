import QtQuick
import ".."

// Full-screen vignette (FR-002a): a radial gradient of ink on a circle of half the screen's
// diagonal, as measured in the game's menus: clear in the middle (the top and bottom centers stay
// paper), ≈#A6A18D at the side edges and ≈#8C8978 in the corners over the paper. Put it last,
// over everything; it takes no input. `enabled: false` hides it.
// It can also paint one piece of a larger vignette: `area` is the whole screen the gradient
// spans and `offset` where this item sits in it (the HUD paints the top strip of the
// desktop's vignette, so the two meet without a seam).
Canvas {
    id: root

    property real s: 1                           // shared interface; the vignette is scale-free
    property size area: Qt.size(width, height)
    property point offset: Qt.point(0, 0)
    // The measured profile by default; a wallpaper scene or the paper filter (spec 004) tunes it.
    property color tint: Tokens.color.darkGray
    property real start: Tokens.vignette.start
    property real edgeAt: Tokens.vignette.edgeAt
    property real edgeAlpha: Tokens.vignette.edgeAlpha
    property real cornerAlpha: Tokens.vignette.cornerAlpha

    visible: enabled

    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.clearRect(0, 0, width, height);        // reset() keeps the pixels: repaints would stack
        const ink = root.tint;
        const rgba = a => `rgba(${Math.round(ink.r * 255)},${Math.round(ink.g * 255)},${Math.round(ink.b * 255)},${a})`;
        const v = root;
        const w = root.area.width, h = root.area.height;
        if (w <= 0 || h <= 0)
            return;
        const cx = w / 2 - root.offset.x, cy = h / 2 - root.offset.y;
        const g = c.createRadialGradient(cx, cy, 0, cx, cy, Math.hypot(w, h) / 2);
        g.addColorStop(0, rgba(0));
        g.addColorStop(v.start, rgba(0));
        g.addColorStop(v.edgeAt, rgba(v.edgeAlpha));
        g.addColorStop(1, rgba(v.cornerAlpha));
        c.fillStyle = g;
        c.fillRect(0, 0, width, height);
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onAreaChanged: requestPaint()
    onOffsetChanged: requestPaint()
    onTintChanged: requestPaint()
    onStartChanged: requestPaint()
    onEdgeAtChanged: requestPaint()
    onEdgeAlphaChanged: requestPaint()
    onCornerAlphaChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
}
