"""Family A: pointers. The approved ship in six directions, plus help (a "?") and not-allowed (the
original's glitch, slices shifted sideways). Progress (the ship with a loading ring) is in
fam_loading."""
import math
import random

import ship
from style import Canvas

ATTRIBUTION = "YoRHa-OS cursor ({}). Shapes after NieR Cursors by Beinsezii (MIT); the ship from NieR:Automata's hacking game."


def _ship(direction, name):
    def fn():
        c = Canvas(ATTRIBUTION.format(name))
        ship.draw(c, direction)
        return [(c.svg(), 0)]
    return fn


def _question(c: Canvas, center, r):
    """A "?" built from the style's primitives: a hooked arc, a short stem and a block dot."""
    cx, cy = center
    c.ring(center, r, r * 0.56, 180, 430, n=40)
    a = math.radians(430)
    mid = r * 0.78
    sx, sy = cx + mid * math.cos(a), cy + mid * math.sin(a)
    w = r * 0.44
    stem = [(sx - w / 2, sy), (sx + w / 2, sy), (sx + w / 2, cy + r * 1.55), (sx - w / 2, cy + r * 1.55)]
    c.plate(stem)
    c.block((sx, cy + r * 2.15), r * 0.3)


def help_():
    c = Canvas(ATTRIBUTION.format("Cursor_Help"))
    ship.draw(c, "up_left")
    _question(c, (102, 22), 14)
    return [(c.svg(), 0)]


def error():
    """The ship, glitching: 8 frames at 8 fps; some clean, some with horizontal slices shifted."""
    base = Canvas(ATTRIBUTION.format("Cursor_Error"))
    ship.draw(base, "up_left")
    inner = base.svg()
    defs = inner[inner.index("<defs>") + 6:inner.index("</defs>")]
    body = inner[inner.index("</defs>") + 7:inner.rindex("</svg>")]
    rnd = random.Random(2026)
    frames = []
    for i in range(8):
        if i in (0, 3, 6):                               # clean frames between the glitches
            frames.append((inner, 125))
            continue
        bands, y = [], 0
        while y < 128:
            h = rnd.choice((4, 6, 8, 10, 14))
            dx = rnd.choice((0, 0, -3, 3, -6, 6, -10, 10))
            bands.append((y, h, dx))
            y += h
        clips = "".join(f'<clipPath id="band{j}"><rect x="-20" y="{y}" width="168" height="{h}"/></clipPath>'
                        for j, (y, h, _) in enumerate(bands))
        uses = "".join(f'<g clip-path="url(#band{j})"><g transform="translate({dx} 0)">{body}</g></g>'
                       for j, (_, _, dx) in enumerate(bands))
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">'
               f'<!-- {ATTRIBUTION.format("Cursor_Error")} -->'
               f'<defs>{defs}{clips}</defs>{uses}</svg>\n')
        frames.append((svg, 125))
    return frames


SHAPES = {
    "Cursor_UL": _ship("up_left", "Cursor_UL"),
    "Cursor_UR": _ship("up_right", "Cursor_UR"),
    "Cursor_L": _ship("left", "Cursor_L"),
    "Cursor_R": _ship("right", "Cursor_R"),
    "Cursor": _ship("up", "Cursor"),
    "Cursor_D": _ship("down", "Cursor_D"),
    "Cursor_Help": help_,
    "Cursor_Error": error,
}
