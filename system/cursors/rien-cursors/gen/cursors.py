"""The 39 cursor shapes of the rien-OS theme: one row per shape, with the hotspot (fraction of
the 128 grid) and the XCursor/CSS aliases. Shapes, hotspots and aliases follow NieR Cursors by
Beinsezii (MIT), build.sh; the pointers' hotspots are their tips.

Each family module exposes SHAPES = {name: fn}, where fn() returns a list of frames
[(content, delay_ms)] (one frame and delay 0 for static shapes). The content is SVG text (drawn
at any size), or {size_px: PIL image} for raster frames (fam_loading).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import ship  # noqa: E402

# name: (family module, hotspot (x, y), aliases)
TABLE = {
    # A. pointers (the ship)
    "Cursor_UL": ("fam_pointer", ship.hotspot("up_left"), "left_ptr arrow default top_left_arrow"),
    "Cursor_UR": ("fam_pointer", ship.hotspot("up_right"), "right_ptr draft_large draft_small"),
    "Cursor_L": ("fam_pointer", ship.hotspot("left"), "sb_left_arrow"),
    "Cursor_R": ("fam_pointer", ship.hotspot("right"), "sb_right_arrow"),
    "Cursor": ("fam_pointer", ship.hotspot("up"), "sb_up_arrow"),
    "Cursor_D": ("fam_pointer", ship.hotspot("down"), "sb_down_arrow"),
    "Cursor_Help": ("fam_pointer", ship.hotspot("up_left"),
                    "question_arrow help left_ptr_help 5c6cd98b3f3ebcb1f9c7f1c204630408 d9ce0ab605698f320427677b458ad60b"),
    "Cursor_Loading": ("fam_loading", ship.hotspot("up_left"),
                       "left_ptr_watch progress 08e8e1c95fe2fc01f976f1e063a24ccd 3ecb610c1bf2410f44200f48c40d3599"),
    "Cursor_Error": ("fam_pointer", ship.hotspot("up_left"), "crossed_circle not-allowed 03b6e0fcb3499374a867c041f52298f0"),
    # B. text
    "Selector": ("fam_text", (0.5, 0.5), "text xterm"),
    "Selector_H": ("fam_text", (0.5, 0.5), "vertical-text"),
    # C. resize (arrow + dot)
    "Arrow_Dot": ("fam_resize", (0.5, 0.5), "n-resize top_side"),
    "Arrow_Dot_UR": ("fam_resize", (0.5, 0.5), "ne-resize top_right_corner"),
    "Arrow_Dot_R": ("fam_resize", (0.5, 0.5), "e-resize right_side"),
    "Arrow_Dot_LR": ("fam_resize", (0.5, 0.5), "se-resize bottom_right_corner"),
    "Arrow_Dot_D": ("fam_resize", (0.5, 0.5), "s-resize bottom_side"),
    "Arrow_Dot_LL": ("fam_resize", (0.5, 0.5), "sw-resize bottom_left_corner"),
    "Arrow_Dot_L": ("fam_resize", (0.5, 0.5), "w-resize left_side"),
    "Arrow_Dot_UL": ("fam_resize", (0.5, 0.5), "nw-resize top_left_corner"),
    "Arrows_Dot_UD": ("fam_resize", (0.5, 0.5),
                      "double_arrow ns-resize row-resize sb_v_double_arrow size_ver v_double_arrow "
                      "00008160000006810000408080010102 2870a09082c103050810ffdffffe0204"),
    "Arrows_Dot_LR": ("fam_resize", (0.5, 0.5),
                      "col-resize ew-resize h_double_arrow sb_h_double_arrow size_hor "
                      "028006030e0e7ebffc7f7070c0600140 14fef782d02440884392942c11205230"),
    "Arrows_Dot_ULLR": ("fam_resize", (0.5, 0.5), "bd_double_arrow nwse-resize size_fdiag c7088f0f3e6c8088236ef8e1e3e70000"),
    "Arrows_Dot_LLUR": ("fam_resize", (0.5, 0.5), "fd_double_arrow nesw-resize size_bdiag fcf1c3c7cd4491d801f1e1c78f100000"),
    "Arrows_Dot_Full": ("fam_resize", (0.5, 0.5), "all-scroll fleur size_all"),
    # D. edge and corner arrows
    "Arrow": ("fam_edge", (0.5, 0.05), "top_tee"),
    "Arrow_UR": ("fam_edge", (0.85, 0.15), "ur_angle"),
    "Arrow_R": ("fam_edge", (0.95, 0.5), "right_tee"),
    "Arrow_LR": ("fam_edge", (0.85, 0.85), "lr_angle"),
    "Arrow_D": ("fam_edge", (0.5, 0.95), "bottom_tee"),
    "Arrow_LL": ("fam_edge", (0.15, 0.85), "ll_angle"),
    "Arrow_L": ("fam_edge", (0.05, 0.5), "left_tee"),
    "Arrow_UL": ("fam_edge", (0.15, 0.15), "ul_angle"),
    "Arrows_Full": ("fam_edge", (0.5, 0.5), "move 4498f0e0c1937ffe01fd06f973665830 9081237383d90e509aa00f00170e968f"),
    # E. hands
    "Hand": ("fam_hand", (0.5, 0.1), "hand1 grab"),
    "Hand_Point": ("fam_hand", (0.375, 0.1),
                   "hand hand2 pointer 9d800788f1b08800ae810202380a0822 e29285e634086352946a0e7090d73106"),
    "Hand_Grab": ("fam_hand", (0.5, 0.5), "grabbing dnd-none"),
    # F. rings
    "Crosshair": ("fam_ring", (0.5, 0.5), "cross crosshair cross_reverse diamond_cross tcross cell"),
    "Targeter": ("fam_ring", (0.5, 0.5675), "dotbox dot_box_mask icon target"),
    "Loading_Circle": ("fam_loading", (0.5, 0.5), "watch wait"),
}


def generate(src_dir, shapes_dir, only=None):
    """Write src/<name>[_NN].svg (or <name>_<size>_<NN>.png) and shapes/<name>/meta.hl for every
    shape (or `only`)."""
    import importlib
    os.makedirs(src_dir, exist_ok=True)
    done = []
    for name, (module, (hx, hy), aliases) in TABLE.items():
        if only and name not in only:
            continue
        try:
            fn = importlib.import_module(module).SHAPES[name]
        except ModuleNotFoundError as e:
            if e.name != module:            # a missing dependency is an error, not a skip
                raise
            print(f"skip {name}: {module} not drawn yet", file=sys.stderr)
            continue
        except KeyError:
            print(f"skip {name}: {module} not drawn yet", file=sys.stderr)
            continue
        frames = fn()
        files = []                          # (size, file, delay); size 0 = vector, any size
        for i, (content, delay) in enumerate(frames):
            if isinstance(content, str):
                fname = f"{name}.svg" if len(frames) == 1 else f"{name}_{i:02d}.svg"
                with open(os.path.join(src_dir, fname), "w") as f:
                    f.write(content)
                files.append((0, fname, delay))
            else:
                for size, img in content.items():
                    fname = f"{name}_{size:03d}_{i:02d}.png"
                    img.save(os.path.join(src_dir, fname))
                    files.append((size, fname, delay))
        files.sort(key=lambda f: f[0])      # each size's frames together, in order
        sdir = os.path.join(shapes_dir, name)
        os.makedirs(sdir, exist_ok=True)
        with open(os.path.join(sdir, "meta.hl"), "w") as f:
            f.write(f"# Generated by gen/cursors.py. {module}.{name}\n")
            f.write("resize_algorithm = bilinear\n")
            f.write(f"hotspot_x = {hx}\nhotspot_y = {hy}\n")
            f.write(f"define_override = {';'.join(aliases.split())}\n")
            animated = len(frames) > 1
            for size, fname, delay in files:
                f.write(f"define_size = {size}, {fname}" + (f", {delay}" if animated else "") + "\n")
        done.append(name)
    return done


if __name__ == "__main__":
    root = os.path.dirname(HERE)
    only = set(sys.argv[1:]) or None
    names = generate(os.path.join(root, "src"), os.path.join(root, "shapes"), only)
    print(f"{len(names)} shapes: {' '.join(names)}")
