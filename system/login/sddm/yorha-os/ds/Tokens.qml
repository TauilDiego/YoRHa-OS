pragma Singleton

import QtQuick

// Port of shell/ds/Tokens.qml for the SDDM greeter (spec 011, research R3): the part of the design
// tokens the login uses, without Quickshell. Keep the numbers in sync with the shell; lab/check-011
// ds-sync compares them. Sizes are the game's pixels at 1080p; components multiply them by `s`.
QtObject {
    id: root

    // --- color -----------------------------------------------------------------------------
    readonly property QtObject color: QtObject {
        readonly property color darkGray: "#4E4B42"      // ink
        readonly property color mediumGray: "#676458"    // secondary ink
        readonly property color lightGray: "#B1AB93"     // resting band, meter track
        readonly property color darkYellow: "#C9C5AB"    // paper
        readonly property color lightYellow: "#D7D1B3"   // card body, inverted text
        readonly property color boxShadow: Qt.rgba(0x7C / 255, 0x7E / 255, 0x6C / 255, 0.69)
        readonly property color textShadow: Qt.rgba(0x7E / 255, 0x7E / 255, 0x74 / 255, 0.57)
        readonly property color alert: "#8F3A30"         // critical states only
        readonly property color dim: Qt.rgba(0x14 / 255, 0x13 / 255, 0x10 / 255, 0.55)
    }

    // --- typography: M PLUS 1 is installed system-wide by the module (no FontLoader here) ----
    readonly property string bodyFamily: "M PLUS 1"
    readonly property string titleFamily: "M PLUS 1"

    // --- shadows ----------------------------------------------------------------------------
    readonly property QtObject shadow: QtObject {
        readonly property real textRatio: 0.15
        readonly property real boxX: 3
        readonly property real boxY: 3
        readonly property real popup: 6
    }

    // --- spacing and sizes (game px at 1080p) -------------------------------------------------
    readonly property QtObject space: QtObject {
        readonly property real tabH: 47
        readonly property real square: 22
        readonly property real listItemH: 48
        readonly property real listItemGap: 12
        readonly property real railGap: 5
        readonly property real rail: 2
        readonly property real rule: 2
        readonly property real selectorW: 32
        readonly property real selectorH: 14
        readonly property real selectorHole: 6
        readonly property real selectorDot: 5
        readonly property real selectorDotOffset: 10
        readonly property real selectorGap: 7
    }

    // --- motion (ms) --------------------------------------------------------------------------
    readonly property QtObject motion: QtObject {
        readonly property int highlight: 150             // ink sweep in
        readonly property int blink: 240                 // selector blink on move, total
        readonly property int popupFade: 150             // the confirmation dialog's fade in
    }
    // The theme's reduceMotion option (FR-032): fades, sweeps and the blink become instant.
    property bool reduced: false
    readonly property bool instant: reduced

    // --- vignette, measured in the game's menus -----------------------------------------------
    readonly property QtObject vignette: QtObject {
        readonly property real start: 0.55
        readonly property real edgeAt: 0.87
        readonly property real edgeAlpha: 0.29
        readonly property real cornerAlpha: 0.50
    }

    // --- the wallpaper's "Menu" scene (spec 004) ------------------------------------------------
    readonly property QtObject wallpaper: QtObject {
        readonly property real lineAlpha: 0.15           // arcs and beams, ink
        readonly property real ruleAlpha: 0.9            // dotted rules over the paper
        readonly property int cycle: 600                 // s, one breathing cycle
        readonly property int arcPeriod: 600
        readonly property int beamPeriod: 300
        readonly property real arcAmplitude: 9           // degrees
        readonly property real beamAmplitude: 70         // game px
    }

    // --- helpers (as in the shell) ------------------------------------------------------------
    function snap(v: real, dpr: real): real {
        return Math.round(v * dpr) / dpr;
    }
    function hair(v: real, dpr: real): real {
        return Math.max(1, Math.round(v * dpr)) / dpr;
    }
    function line(v: real, s: real): int {
        return Math.max(1, Math.round(v * s));
    }
    function px(v: real, s: real): int {
        return Math.round(v * s);
    }
}
