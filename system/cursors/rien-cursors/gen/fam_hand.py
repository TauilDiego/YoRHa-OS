"""Family E: hands. The original's robot hand (three fingers, round knuckles, a slatted thumb
and a wrist joint) re-drawn as light bevelled plates with depth: each finger is a plate with a
groove at its joint, the knuckles are cores, the wrist is a round plate with a core, and the
thumb is a plate with grooves for its slats.

All three hands share the palm, knuckles and wrist, so switching between them does not jump.
Fingers are 16 px wide with centers at x = 48, 64, 80: the open hand's hotspot (0.5, 0.1) is the
middle fingertip and the pointing hand's (0.375, 0.1) the index fingertip, both at y = 12.8.
"""
import math

from fam_ring import disc
from style import Canvas, circle_pts

ATTRIBUTION = "rien-OS cursor ({}). Shapes after NieR Cursors by Beinsezii (MIT)."

TIP_Y = 12.8                       # fingertip line = the hotspots' y (0.1 × 128)
FINGER_X = (48.0, 64.0, 80.0)      # finger centers
FINGER_HALF = 7.4                  # half width (16 px pitch, a small gap shows the depth)
FINGER_BASE = 64.0                 # fingers go under the palm down to here
JOINT_Y = 37.0                     # groove between the two finger segments
TIP_CUT = 3.0                      # chamfer of the fingertip corners
FOLDED_TOP = 52.0                  # top of a folded finger
FOLDED_SEAM = 57.0                 # groove where the folded finger bends
KNUCKLE_Y, KNUCKLE_R = 63.0, 5.4
PALM = [(38.0, 62.0), (90.0, 62.0), (90.0, 100.0), (84.0, 106.0), (44.0, 106.0), (38.0, 100.0)]
WRIST, WRIST_R, WRIST_CORE_R = (64.0, 105.0), 14.6, 5.0


def _bar(p0, p1, half):
    """A rectangle around the segment p0→p1 (half width `half`): p0 side first."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    n = math.hypot(dx, dy)
    nx, ny = -dy / n * half, dx / n * half
    return [(p0[0] + nx, p0[1] + ny), (p1[0] + nx, p1[1] + ny), (p1[0] - nx, p1[1] - ny), (p0[0] - nx, p0[1] - ny)]


def _across(p0, p1, t, half):
    """A seam across the bar p0→p1 at fraction t (slightly longer than the bar is wide)."""
    cx, cy = p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    n = math.hypot(dx, dy)
    nx, ny = -dy / n * (half + 2), dx / n * (half + 2)
    return [(cx + nx, cy + ny), (cx - nx, cy - ny)]


def _finger_up(c: Canvas, x):
    """An extended finger: tip at (x, TIP_Y), chamfered corners, a groove at the joint."""
    h, k = FINGER_HALF, TIP_CUT
    pts = [(x - h, TIP_Y + k), (x - h + k, TIP_Y), (x + h - k, TIP_Y), (x + h, TIP_Y + k),
           (x + h, FINGER_BASE), (x - h, FINGER_BASE)]
    c.plate(pts, seams=[[(x - h - 2, JOINT_Y), (x + h + 2, JOINT_Y)]])


def _finger_folded(c: Canvas, x):
    """A folded finger seen from the front: a short plate with a groove where it bends."""
    h = FINGER_HALF
    pts = [(x - h, FOLDED_TOP), (x + h, FOLDED_TOP), (x + h, FINGER_BASE), (x - h, FINGER_BASE)]
    c.plate(pts, seams=[[(x - h - 2, FOLDED_SEAM), (x + h + 2, FOLDED_SEAM)]])


def _thumb(c: Canvas, tip, base, slats):
    """The slatted thumb: a bar from the tip to under the palm, with grooves across."""
    half = 6.6
    c.plate(_bar(tip, base, half), seams=[_across(tip, base, t, half) for t in slats])


def _thumb_folded(c: Canvas):
    """The folded thumb of the fist: a half disc on the palm's left side with radial slats."""
    center, r = (40.0, 85.0), 13.0
    pts = circle_pts(center, r, 17, 90, 270)
    seams = [[center, (center[0] + (r + 2) * math.cos(math.radians(a)),
                       center[1] + (r + 2) * math.sin(math.radians(a)))] for a in (135, 180, 225)]
    c.plate(pts, seams=seams)


def _hand(c: Canvas, fingers_up):
    for x in FINGER_X:
        (_finger_up if x in fingers_up else _finger_folded)(c, x)
    c.plate(PALM)
    for x in FINGER_X:
        c.core((x, KNUCKLE_Y), KNUCKLE_R)
    disc(c, WRIST, WRIST_R, n=48)
    c.core(WRIST, WRIST_CORE_R)


def hand():
    c = Canvas(ATTRIBUTION.format("Hand"))
    _thumb(c, (21.0, 57.0), (46.0, 94.0), (0.26, 0.48))
    _hand(c, FINGER_X)
    return [(c.svg(), 0)]


def hand_point():
    c = Canvas(ATTRIBUTION.format("Hand_Point"))
    _thumb(c, (11.0, 69.0), (46.0, 91.0), (0.24, 0.46))
    _hand(c, (FINGER_X[0],))
    return [(c.svg(), 0)]


def hand_grab():
    c = Canvas(ATTRIBUTION.format("Hand_Grab"))
    _thumb_folded(c)
    _hand(c, ())
    return [(c.svg(), 0)]


SHAPES = {
    "Hand": hand,
    "Hand_Point": hand_point,
    "Hand_Grab": hand_grab,
}
