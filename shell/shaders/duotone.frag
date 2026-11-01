#version 440
// Duotone app icon (spec 007, research R6): the icon redrawn in the paper's two colors. Its
// luminance picks a color from `ink` (dark) to `paper` (light), and its alpha is kept, so the
// drawing survives (the highlights of a full-color icon become paper inside the ink) and the
// icon sits on the paper as if printed. The luminance is stretched first: a stroke of any
// saturated color (luminance up to ~0.5) is plain ink, and only the light parts turn to paper,
// so a colored line icon never fades into the light-gray box behind it.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 ink;
    vec4 paper;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    float a = c.a;
    // Textures are premultiplied: back to the straight color before measuring it.
    vec3 rgb = a > 0.0 ? c.rgb / a : vec3(0.0);
    float l = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    float t = smoothstep(0.55, 0.9, l);
    vec3 col = mix(ink.rgb, paper.rgb, t);
    fragColor = vec4(col * a, a) * qt_Opacity;
}
