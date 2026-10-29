#!/usr/bin/env bash
# Build the YoRHa-OS cursor theme from the generators: a hyprcursor theme (vector, drawn at the
# exact size by Hyprland) plus an XCursor fallback rendered from the same SVGs. Animated shapes
# keep their frames and delays in both.
# The loading cursors are NieR Cursors' own frames, recolored: their release is fetched per
# yorha-cursors/upstream.lock (or taken from YORHA_UPSTREAM_ARCHIVE) and checked by sha256.
# Needs python3 with Pillow and numpy, hyprcursor-util, rsvg-convert, xcursorgen and curl; run it
# in a container:
#   docker run --rm -v "$REPO:/r:ro" -v "$OUT:/o" archlinux:latest bash -c \
#     'pacman -Sy --noconfirm --needed python python-pillow python-numpy hyprcursor librsvg xorg-xcursorgen >/dev/null &&
#      /r/system/cursors/build.sh /o'
# Usage: build.sh <out-dir>   → <out-dir>/yorha_cursors
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
out=${1:?out dir}
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

# 1. Fetch NieR Cursors' release, then generate the SVGs, PNGs and metas into a scratch copy
# (the repo may be mounted read-only).
url=$(sed -n 's/^url=//p' "$here/yorha-cursors/upstream.lock")
sha=$(sed -n 's/^sha256=//p' "$here/yorha-cursors/upstream.lock")
archive=${YORHA_UPSTREAM_ARCHIVE:-$work/upstream.tar.xz}
[[ -f $archive ]] || curl -fsSL "$url" -o "$archive"
echo "$sha  $archive" | sha256sum -c --quiet
tar xJf "$archive" -C "$work"
export YORHA_UPSTREAM=$work/nier_cursors
cp -r "$here/yorha-cursors" "$work/src-tree"
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
theme="$out/yorha_cursors"
rm -rf "$theme"; mkdir -p "$out"
mv "$work/theme_yorha_cursors" "$theme"

# 3. XCursor fallback: every common size, every frame, same hotspots and aliases. Vector frames
# (size 0) are rendered at each size; raster frames already have theirs.
mkdir -p "$theme/cursors"
for shape in "$src"/shapes/*/; do
    name=$(basename "$shape")
    hx=$(sed -n 's/^hotspot_x *= *//p' "$shape/meta.hl"); hy=$(sed -n 's/^hotspot_y *= *//p' "$shape/meta.hl")
    : > "$work/$name.in"
    sed -n 's/^define_size *= *\([0-9]*\), *\([^,]*\)\(, *\([0-9]*\)\)\?.*/\1 \2 \4/p' "$shape/meta.hl" |
        while read -r size file delay; do
            sizes=("$size"); [[ $size == 0 ]] && sizes=(24 32 40 48 64 80 96 128)
            for s in "${sizes[@]}"; do
                png="$src/src/$file"
                if [[ $file == *.svg ]]; then
                    png="$work/${file%.svg}_$s.png"
                    rsvg-convert -w "$s" -h "$s" "$src/src/$file" -o "$png"
                fi
                printf '%s %s %s %s %s\n' "$s" "$(awk "BEGIN{printf \"%d\", $s*$hx+0.5}")" \
                    "$(awk "BEGIN{printf \"%d\", $s*$hy+0.5}")" "$png" "${delay:-0}" >> "$work/$name.in"
            done
        done
    xcursorgen "$work/$name.in" "$theme/cursors/$name"
    for alias in $(sed -n 's/^define_override *= *//p' "$shape/meta.hl" | tr ';' ' '); do
        ln -sf "$name" "$theme/cursors/$alias"
    done
done
printf '[Icon Theme]\nName=YoRHa-OS Cursors\nComment=NieR-style cursors in the YoRHa-OS palette\nInherits=Adwaita\n' > "$theme/index.theme"
cp "$src/NOTICE" "$theme/"
echo "$theme"
