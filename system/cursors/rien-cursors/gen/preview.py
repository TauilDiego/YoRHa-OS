"""Contact sheet: each of our shapes next to the original (NieR Cursors), at 128 and 48 px, on
the paper and on a terminal. Animated shapes show 4 frames. Needs rsvg-convert and Pillow
(run it in the build container).

Usage: preview.py <src-dir> <orig-dir> <out.png> [names...]
  orig-dir holds the original 128 px frames as <Name>.png (from xcur2png).
"""
import glob
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw

PAPER, TERM = (0xC9, 0xC5, 0xAB), (0x10, 0x10, 0x10)


def render(svg, size):
    with tempfile.NamedTemporaryFile(suffix=".png") as f:
        subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size), svg, "-o", f.name], check=True)
        return Image.open(f.name).convert("RGBA").copy()


def tile(img, bg, box):
    t = Image.new("RGBA", (box, box), bg + (255,))
    t.alpha_composite(img, ((box - img.width) // 2, (box - img.height) // 2))
    return t.convert("RGB")


def main():
    src, orig, out = sys.argv[1:4]
    if sys.argv[4:]:
        names = sys.argv[4:]
    else:                                   # every shape, in the table's order
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        from cursors import TABLE
        names = list(TABLE)
    rows = []
    for n in names:
        files = sorted(glob.glob(os.path.join(src, f"{n}.svg"))) or sorted(glob.glob(os.path.join(src, f"{n}_[0-9][0-9].svg")))
        if not files:
            continue
        pick = files if len(files) == 1 else [files[i * len(files) // 4] for i in range(4)]
        cells = []
        o = os.path.join(orig, f"{n}.png")
        if os.path.exists(o):
            oi = Image.open(o).convert("RGBA")
            cells += [tile(oi, PAPER, 136), tile(oi, TERM, 136)]
        for fpath in pick:
            big = render(fpath, 128)
            cells += [tile(big, PAPER, 136), tile(big, TERM, 136)]
        small = render(pick[0], 48)
        cells += [tile(small, PAPER, 64).resize((136, 136), Image.NEAREST), tile(small, TERM, 64).resize((136, 136), Image.NEAREST)]
        rows.append((n, cells))
    width = 150 + max(len(c) for _, c in rows) * 140
    sheet = Image.new("RGB", (width, len(rows) * 144 + 4), (43, 43, 43))
    d = ImageDraw.Draw(sheet)
    for r, (n, cells) in enumerate(rows):
        d.text((6, r * 144 + 60), n, fill=(235, 235, 235))
        for c, cell in enumerate(cells):
            sheet.paste(cell, (150 + c * 140, r * 144 + 4))
    sheet.save(out)
    print(f"{out}: {len(rows)} shapes")


if __name__ == "__main__":
    main()
