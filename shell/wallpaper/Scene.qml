pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../services"

// A procedural scene (spec 004, research R1), drawn from its JSON (contracts/scene.schema.json):
// the paper and its vignette, the arcs and beams that breathe (PaperDecor, the measured layout),
// the dotted rules at y 108 and 1012 and the dark variant's dot weave. Nothing repaints while the
// scene is still: the dots are painted once, the lines only move with `phase`.
Item {
    id: root

    property var params: ({})
    property real s: 1
    property real phase: 0                       // 0–1 over the shell's 600 s cycle

    readonly property bool dark: params?.kind === "dark"
    readonly property var layers: params?.layers ?? ({})
    readonly property var motion: params?.motion ?? ({})
    readonly property real lineAlpha: params?.lineAlpha ?? 0.15
    readonly property var paper: params?.paper ?? ({})
    readonly property color lineColor: dark ? Tokens.wallpaper.darkLine : Tokens.color.darkGray
    readonly property real shellCycle: 600       // s, shell.qml's wallpaperPhase

    Rectangle {
        anchors.fill: parent
        color: root.paper.center ?? Tokens.color.darkYellow
    }

    // The dark scene's weave: a 1 px dot every 4 px, painted once. (putImageData and ImageData
    // patterns paint nothing in this Canvas; fillRect does, in a few ms.)
    Loader {
        anchors.fill: parent
        active: root.layers.dots === true
        sourceComponent: weave
    }
    Component {
        id: weave
        Canvas {
            onPaint: {
                const c = getContext("2d");
                c.reset();
                c.clearRect(0, 0, width, height);
                const k = Tokens.wallpaper.dotWeave;
                c.fillStyle = `rgba(${Math.round(k.r * 255)},${Math.round(k.g * 255)},${Math.round(k.b * 255)},${k.a})`;
                for (let y = 0; y < height; y += 4)
                    for (let x = 0; x < width; x += 4)
                        c.fillRect(x, y, 1, 1);
            }
            onAvailableChanged: if (available) requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
    }

    PaperDecor {
        anchors.fill: parent
        visible: root.layers.arcs === true || root.layers.beams === true
        showArcs: root.layers.arcs === true
        showBeams: root.layers.beams === true
        ink: Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, root.lineAlpha)
        s: root.s
        phase: root.phase
        arcCycles: root.shellCycle / (root.motion.arcPeriod || root.shellCycle)
        beamCycles: root.shellCycle / (root.motion.beamPeriod || root.shellCycle / 2)
        swing: root.motion.arcAmplitude ?? 9
        slide: root.motion.beamAmplitude ?? 70
    }

    Repeater {
        model: root.layers.rules === true ? [108, 1012] : []

        Rule {
            required property real modelData
            kind: "dotted"
            s: root.s
            y: Math.round(modelData * root.s)
            width: root.width
            color: root.dark
                ? Qt.rgba(Tokens.wallpaper.darkLine.r, Tokens.wallpaper.darkLine.g, Tokens.wallpaper.darkLine.b, Tokens.wallpaper.darkRuleAlpha)
                : Qt.rgba(Tokens.color.darkGray.r, Tokens.color.darkGray.g, Tokens.color.darkGray.b, Tokens.wallpaper.ruleAlpha)
        }
    }

    // The paper scenes keep the measured vignette (the bar paints the same one, FR-004); the dark
    // one darkens toward black, with the strength its JSON's edge and corner colors ask for.
    Vignette {
        anchors.fill: parent
        enabled: Settings.vignette
        tint: root.dark ? Tokens.wallpaper.darkVignette : Tokens.color.darkGray
        edgeAlpha: root.dark ? root.towardTint(root.paper.edge) : Tokens.vignette.edgeAlpha
        cornerAlpha: root.dark ? root.towardTint(root.paper.corner) : Tokens.vignette.cornerAlpha
    }

    // How much of the vignette's tint turns the paper's center into `target` (mean over channels).
    function towardTint(target: string): real {
        const c = Qt.lighter(paper.center ?? "#000000", 1), t = Qt.lighter(target ?? "#000000", 1), k = Tokens.wallpaper.darkVignette;
        let sum = 0, n = 0;
        for (const ch of ["r", "g", "b"]) {
            if (Math.abs(c[ch] - k[ch]) < 1e-6)
                continue;
            sum += (c[ch] - t[ch]) / (c[ch] - k[ch]);
            n++;
        }
        return n ? Math.max(0, Math.min(1, sum / n)) : 0;
    }
}
