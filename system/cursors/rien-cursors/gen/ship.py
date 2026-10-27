"""The ship: the approved default arrow (the hacking ship from NieR:Automata), drawn in any
direction with the same size. Every pointer of family A builds on it.

Upright geometry (tip at 0,0, pointing up, the body going down), in game-ship units; the
style's K turns them into 128-grid px.
"""
from style import Canvas, Xform, K, pts_path

# tip, shoulders, back (75% of the game's length), chevron seam, core, blocks
T, L, R, B = (0, 0), (-27, 66), (27, 66), (0, 91)
Lc, Rc, C = (-22.5, 55), (21.7, 53), (0, 63)
CORE, CORE_R = (0, 64.5), 7.6
BLOCKS = [(-26, 89), (26, 89)]
BLOCK_H = 5.2

# Where the tip goes, per direction: rotation (design → screen) and the tip position.
DIRECTIONS = {
    "up_left": (-35, (5.0, 5.0)),
    "up_right": (35, (123.0, 5.0)),
    "up": (0, (64.0, 5.0)),
    "down": (180, (64.0, 123.0)),
    "left": (-90, (5.0, 64.0)),
    "right": (90, (123.0, 64.0)),
}


def draw(canvas: Canvas, direction="up_left", scale=1.0, tip=None):
    """Draw the ship; returns (xform, tip in grid px) so callers can add details next to it."""
    rot, default_tip = DIRECTIONS[direction]
    tip = tip or default_tip
    xf = Xform(rot, K * scale, tip[0], tip[1])
    P = xf
    kite = [P(T), P(R), P(B), P(L)]
    canvas.plate(kite,
                 seams=[[P(Lc), P(C), P(Rc)], [P(C), P(B)]],
                 lit_edges=[[P(L), P(T), P(R)]] if direction == "up_left" else None,
                 shade_edges=[[P(R), P(B), P(L)]] if direction == "up_left" else None,
                 gradient=(P((-30, 0)), P((30, 100))) if direction == "up_left" else None)
    canvas.core(P(CORE), CORE_R * K * scale)
    for b in BLOCKS:
        canvas.block(P(b), BLOCK_H * K * scale, rot)
    return xf, tip


def hotspot(direction="up_left"):
    _, tip = DIRECTIONS[direction]
    return (round(tip[0] / 128, 4), round(tip[1] / 128, 4))
