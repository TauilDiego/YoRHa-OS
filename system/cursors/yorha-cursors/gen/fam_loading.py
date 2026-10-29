"""Loading cursors: NieR Cursors' own frames (Beinsezii, MIT), which render the game's loading ring
from Blender, recolored to the YoRHa-OS palette. Everything else stays theirs: 90 frames at 60 fps,
the eight sizes, every alpha value. Only the color changes, through a lightness ramp from their
brown tones to the style's palette.

Cursor_Loading keeps our ship and puts their small ring over it, where they put it.

The frames come from their release (upstream.lock); build.sh fetches it and points
YORHA_UPSTREAM at the unpacked theme. Needs Pillow and numpy.
"""
import os
import struct

import numpy as np
from PIL import Image

from style import CORE_RING, CORE, SHADE, PLATE_1, PLATE_0

SIZES = (24, 32, 48, 64, 80, 96, 112, 128)
XCURSOR_IMAGE = 0xFFFD0002

# Their lightness anchors, measured on Loading_Circle at 128 px (Rec. 709 luma of the
# un-premultiplied color): the darkest shadow, the dark ring, the light plate, the brightest
# highlight. The darks land on the style's core colors; the lights keep their lightness (a
# stretched light range turns the plate's faint grid into a checkerboard). The hue always comes
# from the palette ramp.
SRC_L = (46.0, 60.0, 200.0, 209.0)
RAMP = (CORE_RING, CORE, SHADE, PLATE_1, PLATE_0)

# Their small ring on Cursor_Loading, as fractions of the frame (measured at 128 px).
RING_CENTER = (95.5 / 128, 31.5 / 128)
RING_RADIUS = 31.25 / 128
RIM_RADIUS = 29.5 / 128          # the light rim outside the ring's dark outline (static)


def _rgb(hexc):
    return np.array([int(hexc[i:i + 2], 16) for i in (1, 3, 5)], float)


def _luma(rgb):
    return rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722


_RAMP_RGB = np.array([_rgb(c) for c in RAMP])
_RAMP_L = _luma(_RAMP_RGB)
_DST_L = (_luma(_rgb(CORE_RING)), _luma(_rgb(CORE)), SRC_L[2], SRC_L[3])


def recolor(rgba):
    """RGBA uint8 array (straight alpha) → the same pixels in the YoRHa-OS palette."""
    out = rgba.copy()
    lum = np.interp(_luma(rgba[..., :3].astype(float)), SRC_L, _DST_L)
    for ch in range(3):
        out[..., ch] = np.clip(np.interp(lum, _RAMP_L, _RAMP_RGB[:, ch]) + 0.5, 0, 255).astype(np.uint8)
    return out


def read_xcursor(path):
    """{size: [(RGBA uint8 array, delay_ms), ...]} from an XCursor file, alpha un-premultiplied."""
    data = open(path, "rb").read()
    (ntoc,) = struct.unpack_from("<I", data, 12)
    sizes = {}
    for i in range(ntoc):
        kind, size, pos = struct.unpack_from("<III", data, 16 + i * 12)
        if kind != XCURSOR_IMAGE:
            continue
        w, h, _, _, delay = struct.unpack_from("<5I", data, pos + 16)
        bgra = np.frombuffer(data, np.uint8, w * h * 4, pos + 36).reshape(h, w, 4).astype(float)
        a = bgra[..., 3:4]
        rgb = np.where(a > 0, bgra[..., 2::-1] * 255 / np.maximum(a, 1), 0)
        px = np.dstack([np.clip(rgb + 0.5, 0, 255), a]).astype(np.uint8)
        sizes.setdefault(size, []).append((px, delay))
    return sizes


def _upstream(name):
    root = os.environ.get("YORHA_UPSTREAM")
    if not root:
        raise RuntimeError("YORHA_UPSTREAM is not set (build.sh fetches NieR Cursors per upstream.lock)")
    return read_xcursor(os.path.join(root, "nier", name))


def _frames(per_size):
    """{size: [(img, delay)]} → [({size: img}, delay)] frame by frame."""
    n = len(per_size[SIZES[0]])
    return [({s: per_size[s][i][0] for s in SIZES}, per_size[SIZES[0]][i][1]) for i in range(n)]


def loading_circle():
    src = _upstream("Loading_Circle")
    return _frames({s: [(Image.fromarray(recolor(px)), d) for px, d in src[s]] for s in SIZES})


def _ship(size):
    """Our up-left ship at `size` px (the approved arrow, rendered from its SVG)."""
    import subprocess
    import tempfile
    import ship
    from style import Canvas
    c = Canvas("YoRHa-OS cursor (Cursor_Loading).")
    ship.draw(c, "up_left")
    with tempfile.TemporaryDirectory() as tmp:
        svg, png = os.path.join(tmp, "s.svg"), os.path.join(tmp, "s.png")
        open(svg, "w").write(c.svg())
        subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), svg, "-o", png], check=True)
        return Image.open(png).convert("RGBA")


def _rim_profile(px, dist, angle, r_rim, r_max):
    """The ring's outer rim (its edge does not turn), as color and alpha by distance from the
    center: averaged in thin bands where nothing of theirs touches it (upper right, angles on
    screen). Returned as a function that paints the rim at any distance."""
    clean = (dist >= r_rim) & (dist <= r_max) & (angle > -80) & (angle < 20)
    a = px[..., 3][clean].astype(float)
    pre = px[..., :3][clean].astype(float) * a[:, None] / 255          # average premultiplied
    edges = np.arange(r_rim, r_max + 0.25, 0.25)
    band = np.digitize(dist[clean], edges)
    used = [b for b in range(1, len(edges)) if (band == b).any()]
    d = np.array([dist[clean][band == b].mean() for b in used])
    a = np.array([a[band == b].mean() for b in used])
    pre = np.array([pre[band == b].mean(0) for b in used])

    def paint(at):
        alpha = np.interp(at, d, a)
        rgb = np.stack([np.interp(at, d, pre[:, ch]) for ch in range(3)], -1) * 255 / np.maximum(alpha, 1)[..., None]
        return np.dstack([np.clip(rgb + 0.5, 0, 255), alpha]).astype(np.uint8)
    return paint


def cursor_loading():
    src = _upstream("Cursor_Loading")
    per_size = {}
    for s in SIZES:
        base = _ship(s)
        yy, xx = np.mgrid[0:s, 0:s] + 0.5
        cx, cy = RING_CENTER[0] * s, RING_CENTER[1] * s
        dist = np.hypot(xx - cx, yy - cy)
        angle = np.degrees(np.arctan2(yy - cy, xx - cx))
        r_out = RING_RADIUS * s
        r_rim = RIM_RADIUS * s
        # Their arrow runs under the ring's left side and a block touches it below; the rim is
        # repainted everywhere but the clean upper right.
        rim = (dist >= r_rim) & (dist <= r_out + 1) & ((angle < -95) | (angle > 30))
        paint = _rim_profile(src[s][0][0], dist, angle, r_rim, r_out + 1)
        rim_px = paint(dist)
        frames = []
        for px, d in src[s]:
            ring = recolor(np.where(rim[..., None], rim_px, px))
            ring[..., 3] = np.where(dist <= r_out + 1, ring[..., 3], 0)
            img = base.copy()
            img.alpha_composite(Image.fromarray(ring))
            frames.append((img, d))
        per_size[s] = frames
    return _frames(per_size)


SHAPES = {
    "Loading_Circle": loading_circle,
    "Cursor_Loading": cursor_loading,
}
