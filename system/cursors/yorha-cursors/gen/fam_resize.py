"""Family C: resize. One or more arrow heads plus a center dot, like the original: each head is a
light bevelled plate (a right-angle head with a notch cut into its base, the original's open
chevron), and the dot is a small light block (a square, turned into a diamond on the diagonals).

The heads' geometry lives here and family D (fam_edge) reuses it, so both families share the
same heads. The hotspot of every shape here is the center (64, 64), where the dot sits.
"""
from style import (Canvas, DEPTH, DETAIL_W, LIGHT, OUTLINE, SIDE_BOTTOM, SIDE_RIGHT, pts_path,
                   rotate_about, fmt)

ATTRIBUTION = "YoRHa-OS cursor ({}). Shapes after NieR Cursors by Beinsezii (MIT)."

# --- head geometry (128-grid px) ---------------------------------------------------------------
EDGE_TIP = 6.4          # side heads: distance from the tip to the grid edge (= the tee hotspots)
CORNER_TIP = 19.2       # corner heads: the right-angle corner sits at (19.2, 19.2) (= the angle hotspots)
SIDE_L, SIDE_W = 31.0, 31.0          # side head: length (tip to base) and half-width of the base
CORNER_L, CORNER_W = 34.0, 34.0      # corner head: the same right-angle head, a bit bigger (legs 48)
NOTCH_W, NOTCH_D = 8.0, 13.0         # notch in the base: half-width and depth
DOT_HALF = 7.5                       # the center block's half side
CENTER = (64.0, 64.0)

# direction name → (direction in degrees, 0 = right and 90 = down; tip position)
SIDES = {
    "U": (-90.0, (64.0, EDGE_TIP)),
    "R": (0.0, (128.0 - EDGE_TIP, 64.0)),
    "D": (90.0, (64.0, 128.0 - EDGE_TIP)),
    "L": (180.0, (EDGE_TIP, 64.0)),
}
CORNERS = {
    "UL": (-135.0, (CORNER_TIP, CORNER_TIP)),
    "UR": (-45.0, (128.0 - CORNER_TIP, CORNER_TIP)),
    "LR": (45.0, (128.0 - CORNER_TIP, 128.0 - CORNER_TIP)),
    "LL": (135.0, (CORNER_TIP, 128.0 - CORNER_TIP)),
}


def solid_plate(c: Canvas, pts):
    """style.plate for any simple polygon, concave too: depth faces and bevel edges are picked by
    each edge's outward normal (style's own picks use the centroid, which misreads the notch).
    Same colors, widths and depth as style.plate."""
    area2 = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
                for i in range(len(pts)))
    faces, lit, shade = [], [], []
    for i in range(len(pts)):
        (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
        dx, dy = x2 - x1, y2 - y1
        nx, ny = (dy, -dx) if area2 > 0 else (-dy, dx)
        if nx + ny > 1e-6:
            color = SIDE_RIGHT if nx > ny else SIDE_BOTTOM
            quad = [(x1, y1), (x2, y2), (x2 + DEPTH, y2 + DEPTH), (x1 + DEPTH, y1 + DEPTH)]
            faces.append(f'<path d="{pts_path(quad)}" fill="{color}"/>')
        (lit if nx * LIGHT[0] + ny * LIGHT[1] > 1e-6 else shade).append([(x1, y1), (x2, y2)])
    if faces:
        c.raw(f'<g stroke="{OUTLINE}" stroke-width="{fmt(DETAIL_W)}" stroke-linejoin="round">'
              + "".join(faces) + "</g>")
    c.plate(pts, lit_edges=lit, shade_edges=shade, with_depth=False)


def head_pts(tip, deg, length, half_w, notch_w=NOTCH_W, notch_d=NOTCH_D):
    """A right-angle arrow head with a notch in its base, pointing toward `deg`."""
    tx, ty = tip
    local = [(0, 0), (-length, half_w), (-length, notch_w), (-length + notch_d, notch_w),
             (-length + notch_d, -notch_w), (-length, -notch_w), (-length, -half_w)]
    return [rotate_about((tx + x, ty + y), tip, deg) for x, y in local]


def side_head(c: Canvas, side):
    deg, tip = SIDES[side]
    solid_plate(c, head_pts(tip, deg, SIDE_L, SIDE_W))


def corner_head(c: Canvas, corner):
    deg, tip = CORNERS[corner]
    solid_plate(c, head_pts(tip, deg, CORNER_L, CORNER_W))


def head(c: Canvas, where):
    (side_head if where in SIDES else corner_head)(c, where)


def full_heads(c: Canvas):
    """Four side heads whose base corners touch, closing the big diamond outline."""
    tip = EDGE_TIP
    length = (64.0 - tip) / 2           # base corners meet: 64 - half_w == tip + length
    for deg, t in ((-90.0, (64.0, tip)), (180.0, (tip, 64.0)), (0.0, (128.0 - tip, 64.0)),
                   (90.0, (64.0, 128.0 - tip))):
        solid_plate(c, head_pts(t, deg, length, length))


def dot(c: Canvas, diagonal=False):
    c.block(CENTER, DOT_HALF, 45.0 if diagonal else 0.0)


def _shape(name, heads, diagonal):
    def fn():
        c = Canvas(ATTRIBUTION.format(name))
        for h in heads:
            head(c, h)
        dot(c, diagonal)
        return [(c.svg(), 0)]
    return fn


def full():
    c = Canvas(ATTRIBUTION.format("Arrows_Dot_Full"))
    full_heads(c)
    dot(c)
    return [(c.svg(), 0)]


SHAPES = {
    "Arrow_Dot": _shape("Arrow_Dot", ["U"], False),
    "Arrow_Dot_UR": _shape("Arrow_Dot_UR", ["UR"], True),
    "Arrow_Dot_R": _shape("Arrow_Dot_R", ["R"], False),
    "Arrow_Dot_LR": _shape("Arrow_Dot_LR", ["LR"], True),
    "Arrow_Dot_D": _shape("Arrow_Dot_D", ["D"], False),
    "Arrow_Dot_LL": _shape("Arrow_Dot_LL", ["LL"], True),
    "Arrow_Dot_L": _shape("Arrow_Dot_L", ["L"], False),
    "Arrow_Dot_UL": _shape("Arrow_Dot_UL", ["UL"], True),
    "Arrows_Dot_UD": _shape("Arrows_Dot_UD", ["U", "D"], False),
    "Arrows_Dot_LR": _shape("Arrows_Dot_LR", ["L", "R"], False),
    "Arrows_Dot_ULLR": _shape("Arrows_Dot_ULLR", ["UL", "LR"], True),
    "Arrows_Dot_LLUR": _shape("Arrows_Dot_LLUR", ["LL", "UR"], True),
    "Arrows_Dot_Full": full,
}
