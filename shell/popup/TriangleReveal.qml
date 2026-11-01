import QtQuick
import Quickshell.Io
import "../ds"

// The game's triangles over a menu's panel (spec 013, FR-009, research R2): a ShaderEffect
// (shaders/triangles.frag, compiled to .qsb by the lab and versioned) on a live texture of
// `target`, live only while a mode runs (the panel is hidden under it meanwhile).
//   mode     "off" | "grid" (the light grid, color-fringed) | "open" (the cells turn to the panel,
//            some through a dark frame) | "close" (the cells go away);
//   elapsed  ms into the mode; `duration` its length (the cells start within duration − flip);
//   seed     a new order of the cells (PopupFrame draws one per opening and closing).
// The item lies on the panel, as large as the texture (the panel and, floating, its shadow);
// `panelW`/`panelH` are the panel's own size in it: the grid and the dark frames stay inside.
// `ok` is false when the shader is missing or broken: the frame then skips the triangles.
Item {
    id: root

    property Item target: null
    property real s: 1
    property real dpr: 1
    property real panelW: width
    property real panelH: height
    property string mode: "off"
    property real elapsed: 0
    property real duration: 0
    property int seed: 0

    readonly property bool active: mode !== "off"
    // Until the .qsb is known to be missing or broken, it is taken as fine (the probe loads late).
    readonly property bool ok: !missing && effect.status !== ShaderEffect.Error
    readonly property url shaderUrl: Qt.resolvedUrl("shaders/triangles.frag.qsb")
    // Looked for first, so a missing .qsb never reaches the ShaderEffect.
    property bool missing: false
    FileView {
        id: probe
        path: String(root.shaderUrl).replace(/^file:\/\//, "")
        blockLoading: true
        printErrors: false
        onLoadFailed: {
            root.missing = true;
            console.warn("menus: popup/shaders/triangles.frag.qsb is missing; menus open without the triangles");
        }
    }

    // The texture stays made while the panel is there (live only during a mode): making it when the
    // closing starts (a whole screen at hidpi) cost the first frames of the triangles.
    ShaderEffectSource {
        id: texture
        sourceItem: root.ok ? root.target : null
        hideSource: root.active
        live: root.active
        sourceRect: Qt.rect(0, 0, root.width, root.height)
        textureSize: Qt.size(Math.max(1, Math.round(root.width * root.dpr)), Math.max(1, Math.round(root.height * root.dpr)))
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent
        visible: root.active && root.ok
        fragmentShader: root.missing ? "" : root.shaderUrl

        property variant source: texture
        readonly property point area: Qt.point(root.width, root.height)
        readonly property point panel: Qt.point(root.panelW, root.panelH)
        readonly property point cell: Qt.point(Tokens.motion.triW * root.s, Tokens.motion.triH * root.s)
        readonly property real mode: root.mode === "grid" ? 0 : root.mode === "open" ? 1 : 2
        readonly property real elapsed: root.elapsed
        readonly property real flip: 33
        readonly property real span: Math.max(0, root.duration - flip)
        readonly property real darkShare: Tokens.motion.triDark
        readonly property real seed: root.seed
        readonly property real lineW: Tokens.hair(2 * root.s, root.dpr)
        readonly property real fringe: 3 * root.s
    }
}
