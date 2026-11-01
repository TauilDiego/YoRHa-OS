#version 440
// The game's menu opening and closing (spec 013, FR-009, research R2), over a live texture of the
// panel (`source`). The panel is cut in isosceles triangles `cell` wide and tall (240×120 game px:
// the edges run at 45°), pointing up and down in turn, from its top-left corner. Three modes:
//   0 grid: only the triangles' edges, light with a red and a cyan copy beside them;
//   1 open: each cell turns to the panel at its own time within `span`; `darkShare` of them show
//     a dark frame for `flip` ms first; the cells still waiting keep a fainter edge;
//   2 close: each cell goes away at its own time, the dark ones through the dark frame.
// The times come from a hash of the cell and `seed` (a new one each time). Lengths are the item's
// logical px; `panel` is the panel's own rect in it (a floating panel's shadow sticks out of it).
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 area;          // the item, logical px
    vec2 panel;         // the panel inside it
    vec2 cell;          // one triangle's width and height
    float mode;
    float elapsed;      // ms into the mode
    float span;         // ms over which the cells start
    float flip;         // ms a dark cell stays dark
    float darkShare;
    float seed;
    float lineW;        // the edges' width
    float fringe;       // the colored copies' offset
};
layout(binding = 1) uniform sampler2D source;

const vec3 LIGHT = vec3(232.0, 228.0, 212.0) / 255.0;
const vec3 RED = vec3(220.0, 60.0, 60.0) / 255.0;
const vec3 CYAN = vec3(60.0, 190.0, 220.0) / 255.0;
const vec3 DARK = vec3(40.0, 38.0, 33.0) / 255.0;

// The triangle holding p: (row, column) and the distance from p to its nearest edge.
vec3 locate(vec2 p) {
    float h = cell.y, hw = cell.x * 0.5;
    float r = floor(p.y / h);
    float ly = p.y - r * h;
    float u = p.x + hw;                 // the first column starts half a cell left of the panel
    float j = floor(u / hw);            // the half-cell column: triangle j starts in it
    float lx = u - j * hw;
    bool up = mod(r + j, 2.0) < 0.5;    // triangle j points up (its base at the bottom)
    float edge = up ? h * (1.0 - lx / hw) : h * (lx / hw);
    float c = up ? (ly >= edge ? j : j - 1.0) : (ly <= edge ? j : j - 1.0);
    float diag = abs(ly - edge) * hw / sqrt(hw * hw + h * h);
    return vec3(r, c, min(min(ly, h - ly), diag));
}

float hash(vec2 rc, float k) {
    return fract(sin(dot(rc + vec2(seed * 0.6180339, k * 17.0), vec2(12.9898, 78.233))) * 43758.5453);
}

float stroke(float d) {
    return clamp(lineW * 0.5 - d + 0.5, 0.0, 1.0);
}

vec4 over(vec4 dst, vec3 c, float a) {
    return vec4(c * a, a) + dst * (1.0 - a);
}

void main() {
    vec2 p = qt_TexCoord0 * area;
    bool inPanel = p.x < panel.x && p.y < panel.y;
    vec3 at3 = locate(p);
    vec4 o = vec4(0.0);
    if (mode < 0.5) {
        if (inPanel) {
            o = over(o, RED, 0.8 * 0.7 * stroke(locate(p - vec2(fringe, 0.0)).z));
            o = over(o, CYAN, 0.8 * 0.7 * stroke(locate(p + vec2(fringe, 0.0)).z));
            o = over(o, LIGHT, 0.8 * stroke(at3.z));
        }
    } else {
        float at = hash(at3.xy, 1.0) * span;
        bool dark = inPanel && hash(at3.xy, 2.0) < darkShare;
        if (mode < 1.5) {
            if (elapsed >= at + flip || (elapsed >= at && !dark))
                o = texture(source, qt_TexCoord0);
            else if (elapsed >= at)
                o = vec4(DARK * 0.75, 0.75);
            else if (inPanel)
                o = over(o, LIGHT, 0.45 * stroke(at3.z));
        } else {
            if (elapsed < at)
                o = texture(source, qt_TexCoord0);
            else if (elapsed < at + flip && dark)
                o = vec4(DARK * 0.6, 0.6);
        }
    }
    fragColor = o * qt_Opacity;
}
