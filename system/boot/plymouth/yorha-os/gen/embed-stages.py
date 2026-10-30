"""Put the stage catalog (stages.tsv), the options (config) and the letter widths into yorha-os.script
(spec 011, T024).

The Plymouth script can't read files at run time, so both go into the script, between the
"@generated" markers, as plain assignments. The rest of the script is left as it is, and running
this twice gives the same file. Fails, without touching the script, on a malformed line.

Usage: python3 embed-stages.py [theme dir]   (default: the folder above this one)
"""
import os
import re
import sys

GROUPS = ("services", "volumes", "devices", "network", "session", "-")
OPTIONS = {"exit": ("fast", "game"), "effects": ("full", "calm"), "typing": ("instant", "game"), "debug": ("off", "on")}
BEGIN = "# @generated-begin"
END = "# @generated-end"


def fail(path, n, msg):
    sys.exit(f"{path}:{n}: {msg}")


def read_stages(path):
    rows = []
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            line = line.rstrip("\n")
            if not line.strip() or line.startswith("#"):
                continue
            cols = line.split("\t")
            if len(cols) != 3:
                fail(path, n, "three columns separated by one tab")
            pattern, label, group = cols
            if not pattern or pattern.count("*") > 1 or re.search(r'["\\\s]', pattern):
                fail(path, n, f"bad pattern {pattern!r} (at most one '*', no quotes, backslashes or spaces)")
            if not label.isascii() or '"' in label or "\\" in label or len(label) > 48 or not label.strip():
                fail(path, n, f"bad label {label!r} (ASCII, no quotes or backslashes, at most 48 characters)")
            if group not in GROUPS:
                fail(path, n, f"bad group {group!r} (one of {', '.join(GROUPS)})")
            if "*" in pattern:
                a, b = pattern.split("*")
                kind = 1
            else:
                a, b, kind = pattern, "", 0
            rows.append((kind, a, b, "" if label == "-" else label, group))
    return rows


def read_config(path):
    cfg = {k: v[0] for k, v in OPTIONS.items()}
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            key, _, val = (s.strip() for s in line.partition("="))
            if key not in OPTIONS or val not in OPTIONS[key]:
                choices = "; ".join(k + ": " + "|".join(v) for k, v in OPTIONS.items())
                fail(path, n, f"bad option {line!r} ({choices})")
            cfg[key] = val
    return cfg


def read_widths(theme):
    """The advance widths of the boot font's printable ASCII (font units; the script scales them to
    the rendered line's width). The script types a line by cropping its rendered image, so it needs
    where each letter starts. Both label plugins (label-freetype in the initramfs, label-pango after
    the switch to the real root) place the letters by these advances (measured in the lab: the
    rendered widths match to 1 %)."""
    from fontTools.ttLib import TTFont
    f = TTFont(os.path.join(theme, "assets", "font", "YoRHaOSBoot.ttf"))
    cmap, hmtx = f.getBestCmap(), f["hmtx"]
    widths = {}
    for code in range(0x20, 0x7F):
        c = chr(code)
        if c not in '"\\' and code in cmap:
            widths[c] = hmtx[cmap[code]][0]
    return widths


def block(rows, cfg, widths):
    out = [f"{BEGIN} (gen/embed-stages.py, from config, stages.tsv and the font; do not edit by hand)"]
    out += [f'cfg_{k} = "{v}";' for k, v in cfg.items()]
    out.append(f"CW_AVG = {round(sum(widths.values()) / len(widths))};")
    line = []
    for c, w in widths.items():
        line.append(f'CW["{c}"] = {w};')
        if len(line) == 12:
            out.append(" ".join(line))
            line = []
    if line:
        out.append(" ".join(line))
    out.append("st_n = 0;")
    for kind, a, b, label, group in rows:
        out.append(f'st_kind[st_n] = {kind}; st_a[st_n] = "{a}"; st_b[st_n] = "{b}"; '
                   f'st_alen[st_n] = {len(a)}; st_blen[st_n] = {len(b)}; '
                   f'st_label[st_n] = "{label}"; st_group[st_n] = "{group}"; st_n++;')
    out.append(END)
    return "\n".join(out)


def main():
    theme = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    script = os.path.join(theme, "yorha-os.script")
    rows = read_stages(os.path.join(theme, "stages.tsv"))
    cfg = read_config(os.path.join(theme, "config"))
    widths = read_widths(theme)
    with open(script, encoding="utf-8") as f:
        text = f.read()
    i, j = text.find(BEGIN), text.find(END)
    if i < 0 or j < i:
        sys.exit(f"{script}: no '{BEGIN}' ... '{END}' block")
    new = text[:i] + block(rows, cfg, widths) + text[j + len(END):]
    if new != text:
        with open(script, "w", encoding="utf-8") as f:
            f.write(new)
    print(f"{len(rows)} stages, {', '.join(f'{k}={v}' for k, v in cfg.items())} -> {os.path.relpath(script)}"
          f"{'' if new != text else ' (unchanged)'}")


if __name__ == "__main__":
    main()
