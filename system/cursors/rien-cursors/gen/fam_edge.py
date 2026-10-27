"""Family D: edges and corners. The same heads as family C (fam_resize), without the dot: a side
head pressed against an edge (the tees; hotspot on its tip) or a corner head whose right angle
fits a corner (the angles; hotspot on that corner). Move is the four heads closing the big
diamond, like the original (no center element: that one is all-scroll's dot)."""
from style import Canvas
from fam_resize import full_heads, head

ATTRIBUTION = "rien-OS cursor ({}). Shapes after NieR Cursors by Beinsezii (MIT)."


def _shape(name, where):
    def fn():
        c = Canvas(ATTRIBUTION.format(name))
        head(c, where)
        return [(c.svg(), 0)]
    return fn


def full():
    c = Canvas(ATTRIBUTION.format("Arrows_Full"))
    full_heads(c)
    return [(c.svg(), 0)]


SHAPES = {
    "Arrow": _shape("Arrow", "U"),
    "Arrow_UR": _shape("Arrow_UR", "UR"),
    "Arrow_R": _shape("Arrow_R", "R"),
    "Arrow_LR": _shape("Arrow_LR", "LR"),
    "Arrow_D": _shape("Arrow_D", "D"),
    "Arrow_LL": _shape("Arrow_LL", "LL"),
    "Arrow_L": _shape("Arrow_L", "L"),
    "Arrow_UL": _shape("Arrow_UL", "UL"),
    "Arrows_Full": full,
}
