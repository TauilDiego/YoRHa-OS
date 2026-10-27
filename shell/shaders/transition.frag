#version 440
// Wallpaper transitions (spec 004, research R4): one fragment shader, four modes, mixing the old
// picture (`source`) and the new one (`target`), both live textures of the whole monitor.
//   0 camouflage: a wave from `origin`. Just ahead of it the old picture refracts (shaking, then
//     blocky); at the front each cell flashes, comes in pixelated (12, 6, 4 game px) and
//     resolves; behind, a light veil and the cell's outline fade along the trail; rarely a cell
//     fails for one frame (the old picture, or the new one shifted by 2–4 px).
//   1 wipe: the new picture from the left (WipeEdge.qml draws the edge's rule on top).
//   2 tiles: the new picture in 24 px cells, each one after an ink square.
//   3 crossfade.
// Lengths are the monitor's logical px (`unit` = logical px per game px, so every scale looks the
// same), times are ms. Colors come from the Tokens through `ink` and `light`.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float mode;
    float elapsed;      // ms since the change started
    float progress;     // 0–1, eased: wipe, tiles, crossfade
    float revealMs;     // camouflage: the wave's crossing time
    float leadMs;       // camouflage: refraction ahead of the front
    float trailMs;      // camouflage: the trail's length
    float cell;         // camouflage cell, logical px
    float glitch;       // camouflage: failure odds per cell and frame
    float seed;
    float frame;        // a new value every ~33 ms: one failure lasts one mockup frame
    float unit;         // logical px per game px
    float line;         // outline width, logical px (whole physical px)
    float inkSquare;    // tiles: the ink square's strength
    vec2 origin;        // 0–1, where the wave starts
    vec2 itemSize;      // logical px
    vec4 ink;
    vec4 light;
};
layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D target;

// "Hash without Sine", Copyright (c) 2014 David Hoskins, MIT License (CREDITS.md): 0–1, stable
// for a cell, a seed and a frame.
float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.zyx + 31.32);
    return fract((p.x + p.y) * p.z);
}

vec4 at(sampler2D tex, vec2 px) {
    return texture(tex, clamp(px / itemSize, vec2(0.0), vec2(1.0)));
}

// The center of the `size` block that holds px: a mosaic.
vec2 block(vec2 px, float size) {
    return (floor(px / size) + 0.5) * size;
}

vec4 camouflage(vec2 p) {
    vec2 ci = floor(p / cell);
    vec2 f = p - ci * cell;                         // where p sits inside its cell
    vec2 o = origin * itemSize;
    float maxD = length(max(o, itemSize - o));      // the farthest corner
    float r = revealMs * (0.85 * length((ci + 0.5) * cell - o) / maxD + 0.15 * hash(vec3(ci, seed)));
    float age = elapsed - r;

    if (age < -leadMs)
        return at(source, p);

    if (age < 0.0) {                                // refraction ahead of the front
        float k = 1.0 + age / leadMs;               // 0 → 1 as the front nears
        float ph = 6.2832 * hash(vec3(ci, seed + 17.0));
        float t = elapsed / 1000.0;
        vec2 d = floor(vec2(sin(t * 9.0 + ph) * 3.0, cos(t * 7.0 + ph) * 2.0) * k + 0.5) * 2.0 * unit;
        vec2 q = p + d;
        if (k > 0.5)
            q = block(q, 4.0 * unit);
        return at(source, q);
    }

    // the new picture: pixelated, resolving
    float size = age < 130.0 ? 12.0 : (age < 260.0 ? 6.0 : (age < 400.0 ? 4.0 : 0.0));
    vec4 c = at(target, size > 0.0 ? block(p, size * unit) : p);
    bool edge = min(f.x, f.y) < line || max(f.x, f.y) >= cell - line;

    if (age < trailMs) {
        float a = 1.0 - age / trailMs;
        if (hash(vec3(ci, frame + seed * 0.37)) < glitch * a) {        // a one-frame failure
            float h = hash(vec3(ci + 7.0, frame + seed));
            if (h < 0.3) {
                c = at(source, p);
            } else {
                float dir = hash(vec3(ci, frame + 3.0)) < 0.5 ? -1.0 : 1.0;
                float len = hash(vec3(ci + 3.0, frame - seed)) < 0.5 ? 2.0 : 4.0;
                c = at(target, p + vec2(dir * len * unit, 0.0));
            }
        }
        c.rgb = mix(c.rgb, light.rgb, 0.10 * a);                     // the trail: veil…
        if (edge)
            c.rgb = mix(c.rgb, ink.rgb, 0.30 * a);                   // …and outline
    }
    if (age < 60.0 && edge)
        c.rgb = mix(c.rgb, light.rgb, 0.55);                         // the flash at the front
    return c;
}

vec4 wipe(vec2 p) {
    return p.x < progress * (itemSize.x + 40.0 * unit) ? at(target, p) : at(source, p);
}

vec4 tiles(vec2 p) {
    float size = 24.0 * unit;
    vec2 ci = floor(p / size);
    float s = 0.7 * (ci.x / ceil(itemSize.x / size)) + 0.3 * hash(vec3(ci, seed));
    if (progress > s + 0.08)
        return at(target, p);
    vec4 c = at(source, p);
    vec2 f = p - ci * size;
    float m = 4.0 * unit;
    if (progress > s && f.x >= m && f.y >= m && f.x < size - m && f.y < size - m)
        c.rgb = mix(c.rgb, ink.rgb, inkSquare);
    return c;
}

void main() {
    vec2 p = qt_TexCoord0 * itemSize;
    vec4 c;
    if (mode < 0.5)
        c = camouflage(p);
    else if (mode < 1.5)
        c = wipe(p);
    else if (mode < 2.5)
        c = tiles(p);
    else
        c = mix(at(source, p), at(target, p), progress);
    fragColor = c * qt_Opacity;
}
