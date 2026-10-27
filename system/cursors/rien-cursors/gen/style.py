"""rien-OS cursor style: every value the owner approved on the default arrow (2026-10-27), and
the primitives that draw with them. All cursor generators build on this module, so every
shape shares the same palette, line weights, bevel and depth.

Coordinates are the final 128×128 SVG grid (y down). Light comes from the upper left: plates
are lighter there, and the depth (side faces) shows below and to the right.

Approved look ("A, like the game"):
  plates  light, with a bevel (lit upper-left edge, shaded lower-right edge) and an ink outline
  seams   thick grooves (#8B8877) between plates
  core    flat dark gray sphere (#4B4A43), sampled from the game's hacking ship
  blocks  light small squares with depth
  depth   1.8 grid px toward down-right, on every plate and block
"""
import math

# --- palette --------------------------------------------------------------------------------
PLATE_0 = "#F2EFE4"        # plate gradient, lit end
PLATE_1 = "#CCC7B1"        # plate gradient, shaded end
LIT = "#FBFAF4"            # lit edge (upper-left)
SHADE = "#A39E89"          # shaded edge (lower-right)
SEAM = "#8B8877"           # grooves between plates
OUTLINE = "#4E4B42"        # ink outline (reads on the light paper)
CORE = "#4B4A43"           # the core sphere
CORE_RING = "#2F2D28"
BLOCK = "#F2EFE4"          # blocks' top face
SIDE_RIGHT = "#B9B4A0"     # side faces facing right
SIDE_BOTTOM = "#8B8877"    # side faces facing down

# --- measures (128-grid px) -------------------------------------------------------------------
K = 1.2413250918249776     # the arrow's design scale (game-ship units → grid px)
EDGE = 1.9 * K * 0.45      # outline width
SEAM_W = 2.3 * K * 1.4     # groove width (thicker, approved)
BEVEL_W = EDGE * 1.6       # lit/shaded edge width
DETAIL_W = EDGE * 0.9      # outlines of cores, blocks and side faces
DEPTH = 1.8                # extrusion toward down-right
LIGHT = (-1.0, -1.0)       # light direction (from where it comes)


def fmt(v: float) -> str:
    return f"{v:.2f}"


def pts_path(pts, close=True) -> str:
    d = "M" + " L".join(f"{fmt(x)} {fmt(y)}" for x, y in pts)
    return d + (" Z" if close else "")


class Xform:
    """Design space → grid: rotate (degrees, about the origin), scale, then translate."""

    def __init__(self, rot=0.0, scale=1.0, tx=0.0, ty=0.0):
        self.a, self.s, self.tx, self.ty = math.radians(rot), scale, tx, ty

    def __call__(self, p):
        x, y = p
        c, s = math.cos(self.a), math.sin(self.a)
        return (self.s * (x * c - y * s) + self.tx, self.s * (x * s + y * c) + self.ty)

    def many(self, ps):
        return [self(p) for p in ps]


def rotate_about(p, center, deg):
    a = math.radians(deg)
    x, y = p[0] - center[0], p[1] - center[1]
    return (center[0] + x * math.cos(a) - y * math.sin(a), center[1] + x * math.sin(a) + y * math.cos(a))


def circle_pts(center, r, n=48, a0=0.0, a1=360.0):
    return [(center[0] + r * math.cos(math.radians(a)), center[1] + r * math.sin(math.radians(a)))
            for a in (a0 + (a1 - a0) * i / (n - 1 if a1 - a0 < 360 else n) for i in range(n))]


def annulus_sector(center, r_out, r_in, a0, a1, n=32):
    """A thick arc as one polygon (outer arc forward, inner arc back)."""
    outer = circle_pts(center, r_out, n, a0, a1)
    inner = circle_pts(center, r_in, n, a0, a1)[::-1]
    return outer + inner


class Canvas:
    """Collects layers (in draw order) and defs, then writes the SVG."""

    def __init__(self, comment=""):
        self.comment = comment
        self.defs = []
        self.layers = []
        self._ids = 0

    def _id(self, base):
        self._ids += 1
        return f"{base}{self._ids}"

    # --- primitives -------------------------------------------------------------------------
    def depth(self, pts):
        """Side faces of a polygon that face down-right (its thickness), drawn under it."""
        cx, cy = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
        out = []
        for i in range(len(pts)):
            (x1, y1), (x2, y2) = pts[i], pts[(i + 1) % len(pts)]
            mx, my = (x1 + x2) / 2 - cx, (y1 + y2) / 2 - cy
            if mx + my <= 0:
                continue
            color = SIDE_RIGHT if mx > my else SIDE_BOTTOM
            quad = [(x1, y1), (x2, y2), (x2 + DEPTH, y2 + DEPTH), (x1 + DEPTH, y1 + DEPTH)]
            out.append(f'<path d="{pts_path(quad)}" fill="{color}"/>')
        if out:
            self.layers.append(f'<g stroke="{OUTLINE}" stroke-width="{fmt(DETAIL_W)}" stroke-linejoin="round">'
                               + "".join(out) + "</g>")

    def plate(self, pts, seams=(), lit_edges=None, shade_edges=None, gradient=None, with_depth=True):
        """A plate: depth, gradient fill (light from the upper left), bevel edges, grooves,
        outline. `seams` are polylines clipped to the plate. `lit_edges`/`shade_edges` are
        polylines; by default they are the polygon edges facing the light / away from it.
        `gradient` = (p0, p1) overrides the gradient axis."""
        if with_depth:
            self.depth(pts)
        gid, cid = self._id("plate"), self._id("clip")
        xs, ys = [p[0] for p in pts], [p[1] for p in pts]
        g0, g1 = gradient or ((min(xs), min(ys)), (max(xs), max(ys)))
        self.defs.append(
            f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" x1="{fmt(g0[0])}" y1="{fmt(g0[1])}" '
            f'x2="{fmt(g1[0])}" y2="{fmt(g1[1])}"><stop offset="0" stop-color="{PLATE_0}"/>'
            f'<stop offset="1" stop-color="{PLATE_1}"/></linearGradient>')
        self.defs.append(f'<clipPath id="{cid}"><path d="{pts_path(pts)}"/></clipPath>')
        self.layers.append(f'<path d="{pts_path(pts)}" fill="url(#{gid})"/>')
        if lit_edges is None or shade_edges is None:
            lit, shade = self._split_edges(pts)
            lit_edges = lit if lit_edges is None else lit_edges
            shade_edges = shade if shade_edges is None else shade_edges
        bevel = "".join(f'<path d="{pts_path(e, False)}" stroke="{LIT}"/>' for e in lit_edges)
        bevel += "".join(f'<path d="{pts_path(e, False)}" stroke="{SHADE}"/>' for e in shade_edges)
        self.layers.append(f'<g clip-path="url(#{cid})" fill="none" stroke-width="{fmt(BEVEL_W)}">{bevel}</g>')
        if seams:
            self.layers.append(
                f'<g fill="none" stroke="{SEAM}" stroke-width="{fmt(SEAM_W)}" stroke-linejoin="miter" '
                f'clip-path="url(#{cid})">' + "".join(f'<path d="{pts_path(s, False)}"/>' for s in seams) + "</g>")
        self.layers.append(f'<path d="{pts_path(pts)}" fill="none" stroke="{OUTLINE}" stroke-width="{fmt(EDGE)}" '
                           f'stroke-linejoin="miter" stroke-miterlimit="20"/>')

    @staticmethod
    def _split_edges(pts):
        """Edges facing the light (lit) and the others (shade), each as a 2-point polyline."""
        cx, cy = sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)
        lit, shade = [], []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            mx, my = (a[0] + b[0]) / 2 - cx, (a[1] + b[1]) / 2 - cy
            (lit if mx * LIGHT[0] + my * LIGHT[1] > 0 else shade).append([a, b])
        return lit, shade

    def core(self, center, r):
        """The flat dark sphere."""
        self.layers.append(f'<circle cx="{fmt(center[0])}" cy="{fmt(center[1])}" r="{fmt(r)}" fill="{CORE}" '
                           f'stroke="{CORE_RING}" stroke-width="{fmt(DETAIL_W)}"/>')

    def block(self, center, half, deg=0.0):
        """A small light block with depth."""
        sq = [(-half, -half), (half, -half), (half, half), (-half, half)]
        pts = [rotate_about((center[0] + x, center[1] + y), center, deg) for x, y in sq]
        self.depth(pts)
        self.layers.append(f'<path d="{pts_path(pts)}" fill="{BLOCK}" stroke="{OUTLINE}" '
                           f'stroke-width="{fmt(DETAIL_W)}" stroke-linejoin="miter"/>')

    def ring(self, center, r_out, r_in, a0=0.0, a1=360.0, n=64):
        """A thick ring or arc as a plate (with bevel and depth)."""
        if a1 - a0 >= 360:
            # full ring: two half sectors, so each polygon stays simple
            self.plate(annulus_sector(center, r_out, r_in, a0, a0 + 180, n // 2 + 1))
            self.plate(annulus_sector(center, r_out, r_in, a0 + 180, a0 + 360, n // 2 + 1))
        else:
            self.plate(annulus_sector(center, r_out, r_in, a0, a1, max(8, int(n * (a1 - a0) / 360))))

    def arrowhead(self, tip, direction_deg, length, width):
        """A solid triangular arrow head pointing toward `direction_deg` (0 = right, 90 = down)."""
        base_c = rotate_about((tip[0] - length, tip[1]), tip, direction_deg)
        pts = [tip,
               rotate_about((tip[0] - length, tip[1] + width / 2), tip, direction_deg),
               rotate_about((tip[0] - length, tip[1] - width / 2), tip, direction_deg)]
        self.plate(pts)
        return base_c

    def raw(self, svg_fragment):
        self.layers.append(svg_fragment)

    # --- output -----------------------------------------------------------------------------
    def svg(self) -> str:
        defs = "\n    ".join(self.defs)
        body = "\n  ".join(self.layers)
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" width="128" height="128">\n'
                f'  <!-- {self.comment} -->\n  <defs>\n    {defs}\n  </defs>\n  {body}\n</svg>\n')


def write(path, canvas):
    with open(path, "w") as f:
        f.write(canvas.svg())
