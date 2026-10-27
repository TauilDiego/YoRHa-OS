#!/usr/bin/env bash
# Build the rien-OS cursor theme from the generators: a hyprcursor theme (vector, drawn at the
# exact size by Hyprland) plus an XCursor fallback rendered from the same SVGs. Animated shapes
# keep their frames and delays in both.
# Needs python3, hyprcursor-util, rsvg-convert and xcursorgen; run it in a container:
#   docker run --rm -v "$REPO:/r:ro" -v "$OUT:/o" archlinux:latest bash -c \
#     'pacman -Sy --noconfirm --needed python hyprcursor librsvg xorg-xcursorgen >/dev/null && /r/system/cursors/build.sh /o'
# Usage: build.sh <out-dir>   → <out-dir>/rien_cursors
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
out=${1:?out dir}
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

# 1. Generate the SVGs and metas into a scratch copy (the repo may be mounted read-only).
cp -r "$here/rien-cursors" "$work/src-tree"
rm -rf "$work/src-tree/src" "$work/src-tree/shapes"
python3 "$work/src-tree/gen/cursors.py" >/dev/null
src="$work/src-tree"

# 2. hyprcursor: manifest + one folder per shape with its meta and SVG frames.
mkdir -p "$work/tree/hyprcursors"
cp "$src/manifest.hl" "$work/tree/"
for shape in "$src"/shapes/*/; do
    name=$(basename "$shape")
    mkdir -p "$work/tree/hyprcursors/$name"
    cp "$shape/meta.hl" "$work/tree/hyprcursors/$name/"
    sed -n 's/^define_size *= *[0-9]*, *\([^,]*\).*/\1/p' "$shape/meta.hl" |
        while read -r svg; do cp "$src/src/$svg" "$work/tree/hyprcursors/$name/"; done
done
hyprcursor-util --create "$work/tree" --output "$work" >/dev/null
theme="$out/rien_cursors"
rm -rf "$theme"; mkdir -p "$out"
mv "$work/theme_rien_cursors" "$theme"

# 3. XCursor fallback: every common size, every frame, same hotspots and aliases.
mkdir -p "$theme/cursors"
for shape in "$src"/shapes/*/; do
    name=$(basename "$shape")
    hx=$(sed -n 's/^hotspot_x *= *//p' "$shape/meta.hl"); hy=$(sed -n 's/^hotspot_y *= *//p' "$shape/meta.hl")
    : > "$work/$name.in"
    sed -n 's/^define_size *= *[0-9]*, *\([^,]*\)\(, *\([0-9]*\)\)\?.*/\1 \3/p' "$shape/meta.hl" |
        while read -r svg delay; do
            for s in 24 32 40 48 64 80 96 128; do
                png="$work/${svg%.svg}_$s.png"
                rsvg-convert -w "$s" -h "$s" "$src/src/$svg" -o "$png"
                printf '%s %s %s %s %s\n' "$s" "$(awk "BEGIN{printf \"%d\", $s*$hx+0.5}")" \
                    "$(awk "BEGIN{printf \"%d\", $s*$hy+0.5}")" "$png" "${delay:-0}" >> "$work/$name.in"
            done
        done
    xcursorgen "$work/$name.in" "$theme/cursors/$name"
    for alias in $(sed -n 's/^define_override *= *//p' "$shape/meta.hl" | tr ';' ' '); do
        ln -sf "$name" "$theme/cursors/$alias"
    done
done
printf '[Icon Theme]\nName=rien-OS Cursors\nComment=NieR-style cursors in the rien-OS palette\nInherits=Adwaita\n' > "$theme/index.theme"
cp "$src/NOTICE" "$theme/"
echo "$theme"
