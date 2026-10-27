"""Family F: rings. The crosshair (a ring broken in three arcs, with a dot on the hotspot), the
targeter (three thin arcs around the hotspot and three dots at the gaps; the original's red
becomes the style's light plates, and each dot a small round plate with a core) and the big
wait spinner (a round plate, a raised inner ring and a dark arc running around between them,
24 frames like Cursor_Loading)."""
import math

from style import (Canvas, CORE, OUTLINE, DETAIL_W, DEPTH, SIDE_RIGHT, SIDE_BOTTOM, fmt, annulus_sector,
                   pts_path, circle_pts)

ATTRIBUTION = "rien-OS cursor ({}). Shapes after NieR Cursors by Beinsezii (MIT)."

CENTER = (64.0, 64.0)


def _polar(center, r, deg):
    return (center[0] + r * math.cos(math.radians(deg)), center[1] + r * math.sin(math.radians(deg)))


def disc(c: Canvas, center, r, grooves=(), n=72):
    """A round plate. Its depth is one circle shifted by DEPTH toward down-right (the style's
    side colors as a gradient), instead of one quad per polygon edge, which would show as ticks
    around a round rim. `grooves` are radii of circular seams on the plate."""
    gid = c._id("side")
    x0, y0 = center[0] + DEPTH - r, center[1] + DEPTH - r
    c.defs.append(f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{fmt(x0 + 2 * r)}" '
                  f'y1="{fmt(y0)}" x2="{fmt(x0)}" y2="{fmt(y0 + 2 * r)}"><stop offset="0" stop-color="{SIDE_RIGHT}"/>'
                  f'<stop offset="1" stop-color="{SIDE_BOTTOM}"/></linearGradient>')
    c.raw(f'<circle cx="{fmt(center[0] + DEPTH)}" cy="{fmt(center[1] + DEPTH)}" r="{fmt(r)}" fill="url(#{gid})" '
          f'stroke="{OUTLINE}" stroke-width="{fmt(DETAIL_W)}"/>')
    seams = [circle_pts(center, g, n) + [circle_pts(center, g, n)[0]] for g in grooves]
    c.plate(circle_pts(center, r, n), seams=seams, with_depth=False)


def _stud(c: Canvas, center, r=7.5):
    """A dot: a small round plate with a core, so it reads on dark backgrounds too."""
    disc(c, center, r, n=32)
    c.core(center, r * 0.48)


def crosshair():
    """Angles are on screen (0 = right, 90 = down): gaps at upper left, upper right and bottom."""
    c = Canvas(ATTRIBUTION.format("Crosshair"))
    for a in (210, 330, 90):
        c.ring(CENTER, 56, 46, a + 12, a + 108)
    _stud(c, CENTER, 9)
    return [(c.svg(), 0)]


def targeter():
    c = Canvas(ATTRIBUTION.format("Targeter"))
    center = (64.0, 0.5675 * 128)           # the hotspot (72.64)
    for a in (270, 30, 150):                # gaps at top, lower right, lower left
        c.ring(center, 36, 28, a + 9, a + 111)
    for a in (270, 30, 150):                # a dot in front of each gap
        _stud(c, _polar(center, 58, a))
    return [(c.svg(), 0)]


def _dark_arc(c: Canvas, center, r_out, r_in, a0, a1):
    arc = annulus_sector(center, r_out, r_in, a0, a1, 24)
    c.raw(f'<path d="{pts_path(arc)}" fill="{CORE}" stroke="{OUTLINE}" stroke-width="{fmt(DETAIL_W)}"/>')


def loading_circle():
    frames = []
    n = 24
    for i in range(n):
        c = Canvas(ATTRIBUTION.format("Loading_Circle"))
        disc(c, CENTER, 57, n=96)
        a = 360 * i / n
        _dark_arc(c, CENTER, 52, 37, a, a + 100)
        disc(c, CENTER, 30, grooves=(18,))
        frames.append((c.svg(), 1000 // n))
    return frames


SHAPES = {
    "Crosshair": crosshair,
    "Targeter": targeter,
    "Loading_Circle": loading_circle,
}
