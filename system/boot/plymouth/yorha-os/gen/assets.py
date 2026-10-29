"""Images and font of the YoRHa-OS boot screen (spec 011, T023), made once in the lab and committed.

The Plymouth script can't process pixels, so everything that would need it comes out of here as an
image. Numbers come from the 4K analysis of the game's boot (values in 4K px unless noted; 1080p is
half), and the look follows the reproduction the owner approved (artifact f3ee156f):

- film-<p>.png      the LCD film tile, period p px (14 px in 4K, 7 px in 1080p): a clear cell and a
                    dark gap (cell rgb(27,24,20), gap rgb(12,7,4) over the background). One tile per
                    period, so the script picks the one that stays crisp at the screen's height.
- vignette.png      the side vignette (-30 to -55 % at the edges, -8 % top, -14 % bottom), small;
                    the script stretches it (it is smooth).
- rings.png         the faint concentric rings shown inside the interference bands (centre near
                    the screen centre, ~200 px apart in 4K), full screen at 1080p; the script crops
                    the band out of it.
- band-cap-l.png,   the ends of the passage band: 2 arcs (centre (187,694), radii 442 and 487) and
  band-cap-r.png    2 diagonals, the right one the point mirror of the left, at 4K.
- band-dots-<p>.png the band's faint dark dots, period p px (20 px in 4K).
- px-*.png          one-pixel images the script scales into flat strips (background, black, band).
- font/             M PLUS 1 as a static instance, cut down to Latin, renamed "YoRHa-OS Boot": the
                    initramfs label plugin (label-freetype) loads one file and can't pick a weight
                    of a variable font, so the variable file would draw in Thin (its default).

Run in the lab (lab/011/boot-assets), never on the owner's machine. Needs Pillow, numpy and
fontTools. Usage: python3 assets.py <theme dir> <M PLUS 1 variable font>
"""
import math
import os
import sys

import numpy as np
from PIL import Image

CELL = (27, 24, 20)            # the film's cell, also the screen background
GAP = (12, 7, 4)               # the film's gap
BAND = (15, 15, 15)            # the passage band
RING_RGB = (230, 225, 204)     # the rings, as in the reproduction
FONT_WEIGHT = 600              # SemiBold: between the header (500) and the lines (700) of the reproduction
FONT_FAMILY = "YoRHa-OS Boot"
FONT_FILE = "YoRHaOSBoot.ttf"
# What the boot and the shutdown band draw: ASCII (the initramfs draws nothing else), Latin-1 and
# the punctuation the shutdown band uses ("…", dashes, quotes).
FONT_CHARS = list(range(0x20, 0x7F)) + list(range(0xA0, 0x100)) + [0x2013, 0x2014, 0x2018, 0x2019,
                                                                    0x201C, 0x201D, 0x2026]


def save(img, path):
    img.save(path, optimize=True)
    print(f"{os.path.relpath(path)}  {img.size[0]}x{img.size[1]}  {os.path.getsize(path)} B")


def gap_overlay():
    """The film is drawn over the content as an overlay that only covers the gaps. Solve for a
    color and alpha that turn the cell color into the gap color (least squares, color >= 0)."""
    best = None
    for a in np.arange(0.50, 0.90, 0.01):
        c = np.clip((np.array(GAP) - np.array(CELL) * (1 - a)) / a, 0, 255)
        err = np.abs(np.array(CELL) * (1 - a) + c * a - np.array(GAP)).sum()
        if best is None or err < best[0]:
            best = (err, a, c)
    _, a, c = best
    return tuple(int(round(v)) for v in c), a


def film(out):
    color, alpha = gap_overlay()
    for p in range(4, 17):
        gap = max(1, round(p * 4 / 14))
        cell = p - gap
        a = np.zeros((p, p, 4), np.uint8)
        a[..., :3] = color
        a[cell:, :, 3] = round(alpha * 255)
        a[:, cell:, 3] = round(alpha * 255)
        save(Image.fromarray(a, "RGBA"), os.path.join(out, f"film-{p}.png"))


def vignette(out):
    # The reproduction's stops (fraction of the width -> darkening), from the measured sides.
    hx = [(0, .5), (.04, .27), (.1, .2), (.2, .1), (.33, 0), (.67, 0), (.8, .1), (.9, .2), (.96, .27), (1, .32)]
    w, h = 384, 216
    x = (np.arange(w) + 0.5) / w
    y = (np.arange(h) + 0.5) / h
    ah = np.interp(x, [p for p, _ in hx], [v for _, v in hx])
    av = np.interp(y, [0, .5, 1], [.08, 0, .14])
    alpha = 1 - (1 - av[:, None]) * (1 - ah[None, :])
    a = np.zeros((h, w, 4), np.uint8)
    a[..., 3] = np.round(alpha * 255)
    save(Image.fromarray(a, "RGBA"), os.path.join(out, "vignette.png"))


def rings(out):
    # 1080p: centre (0.527 W, 0.48 H), 97.5 px apart, ~1.5 px lines at 5 % (the reproduction).
    w, h, step, peak = 1920, 1080, 97.5, 0.05
    yy, xx = np.mgrid[0:h, 0:w].astype(float) + 0.5
    r = np.hypot(xx - 0.527 * w, yy - 0.48 * h)
    d = np.abs(r - np.round(r / step) * step)
    cov = np.clip(1.25 - d, 0, 1)
    cov[r < step / 2] = 0
    a = np.zeros((h, w, 4), np.uint8)
    a[..., :3] = RING_RGB
    a[..., 3] = np.round(cov * peak * 255)
    save(Image.fromarray(a, "RGBA"), os.path.join(out, "rings.png"))


def band_caps(out):
    """The left end of the passage band at 4K (band y 903..1286, 383 px tall), and its point mirror.
    Lines: rgb(200,200,200) at 32 % (the reproduction), 2 px at 4K so they stay 1 px at 1080p."""
    top, bh, w = 903, 383, 900
    ss = 4                                  # supersampling
    yy, xx = np.mgrid[0:bh * ss, 0:w * ss].astype(float)
    xx = (xx + 0.5) / ss
    yy = (yy + 0.5) / ss + top
    half = 1.0                              # half the line width
    cov = np.zeros_like(xx)
    for r in (442, 487):
        cov = np.maximum(cov, np.clip(half + 0.5 - np.abs(np.hypot(xx - 187, yy - 694) - r), 0, 1))
    for (x0, y0), (x1, y1) in (((234, 903), (712, 1122)), ((328, 903), (821, 1240))):
        dx, dy = x1 - x0, y1 - y0
        length = math.hypot(dx, dy)
        t = ((xx - x0) * dx + (yy - y0) * dy) / (length * length)
        dist = np.abs((xx - x0) * dy - (yy - y0) * dx) / length
        cov = np.maximum(cov, np.clip(half + 0.5 - dist, 0, 1) * (t >= 0) * (t <= 1))
    cov = cov.reshape(bh, ss, w, ss).mean(axis=(1, 3))
    a = np.zeros((bh, w, 4), np.uint8)
    a[..., :3] = 200
    a[..., 3] = np.round(cov * 0.32 * 255)
    save(Image.fromarray(a, "RGBA"), os.path.join(out, "band-cap-l.png"))
    save(Image.fromarray(a[::-1, ::-1].copy(), "RGBA"), os.path.join(out, "band-cap-r.png"))


def band_dots(out):
    # 20 px apart at 4K, 4 px dots at 22 % black (the reproduction): 10 px and 2 px at 1080p.
    for p in range(5, 21):
        dot = max(1, round(p / 5))
        a = np.zeros((p, p, 4), np.uint8)
        o = (p - dot) // 2
        a[o:o + dot, o:o + dot, 3] = round(0.22 * 255)
        save(Image.fromarray(a, "RGBA"), os.path.join(out, f"band-dots-{p}.png"))


def pixels(out):
    for name, rgb in (("px-bg", CELL), ("px-black", (0, 0, 0)), ("px-band", BAND)):
        save(Image.new("RGBA", (1, 1), rgb + (255,)), os.path.join(out, f"{name}.png"))


def font(out, variable):
    from fontTools import subset
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    f = TTFont(variable)
    f = instancer.instantiateVariableFont(f, {"wght": FONT_WEIGHT})
    opts = subset.Options()
    opts.layout_features = ["kern", "liga", "calt"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=FONT_CHARS)
    sub.subset(f)
    style = "Regular"
    names = {1: FONT_FAMILY, 2: style, 3: f"{FONT_FAMILY.replace(' ', '')}-{FONT_WEIGHT}",
             4: FONT_FAMILY, 6: FONT_FAMILY.replace(" ", ""), 16: FONT_FAMILY, 17: style}
    for rec in list(f["name"].names):
        if rec.nameID in (16, 17, 21, 22, 25) or rec.nameID >= 256:
            f["name"].removeNames(nameID=rec.nameID)
    for nid, val in names.items():
        f["name"].setName(val, nid, 3, 1, 0x409)
        f["name"].setName(val, nid, 1, 0, 0)
    f["OS/2"].usWeightClass = 400       # one face of its own family: fontconfig sees it as the regular
    f["head"].macStyle = 0
    note = (f"Derived from M PLUS 1 (The M+ FONTS Project Authors, SIL OFL 1.1): static instance "
            f"wght={FONT_WEIGHT}, Latin subset, renamed for the YoRHa-OS boot screen.")
    f["name"].setName(note, 10, 3, 1, 0x409)
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, FONT_FILE)
    f.save(path)
    print(f"{os.path.relpath(path)}  {os.path.getsize(path)} B  (ascender {f['hhea'].ascent}, "
          f"descender {f['hhea'].descent}, units/em {f['head'].unitsPerEm})")


def main():
    theme, variable = sys.argv[1], sys.argv[2]
    out = os.path.join(theme, "assets")
    os.makedirs(out, exist_ok=True)
    film(out)
    vignette(out)
    rings(out)
    band_caps(out)
    band_dots(out)
    pixels(out)
    font(os.path.join(out, "font"), variable)


if __name__ == "__main__":
    main()
