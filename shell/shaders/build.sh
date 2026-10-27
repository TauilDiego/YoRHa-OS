#!/usr/bin/env bash
# Compile the shell's fragment shaders (*.frag, GLSL 440) to Qt's .qsb format where the UI runs:
# the lab VM today, the installer later (spec 004, research R3). The .qsb files stay out of git.
# Only a shader newer than its .qsb is rebuilt. Without qsb (package qt6-shadertools) it warns and
# exits 0: the wallpaper transitions then fall back to a plain crossfade.
# Usage: shaders/build.sh
set -euo pipefail

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
qsb=$(command -v qsb || true)
if [[ -z $qsb && -x /usr/lib/qt6/bin/qsb ]]; then
    qsb=/usr/lib/qt6/bin/qsb
fi
if [[ -z $qsb ]]; then
    echo "shaders: qsb not found (qt6-shadertools); wallpaper transitions fall back to a crossfade" >&2
    exit 0
fi

shopt -s nullglob
for frag in "$dir"/*.frag; do
    out="$frag.qsb"
    if [[ -f $out && $out -nt $frag ]]; then
        continue
    fi
    "$qsb" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$out" "$frag"
    echo "shaders: built $(basename "$out")"
done
