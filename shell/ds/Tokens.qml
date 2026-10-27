pragma Singleton

import QtQuick
import Quickshell

// Design tokens: the single source of every value in docs/design-system.md.
// Sizes are the game's pixels at 1080p; components multiply them by their surface factor `s`.
// Values from "NieR: Automata - UI" by tyleo (CC BY 4.0), adapted for the desktop.
Singleton {
    id: root

    // --- color (FR-001) -----------------------------------------------------------------
    readonly property Colors color: Colors {}
    component Colors: QtObject {
        readonly property color darkGray: "#4E4B42"      // ink
        readonly property color mediumGray: "#676458"    // secondary ink
        readonly property color lightGray: "#B1AB93"     // resting tab/button, meter track
        readonly property color darkYellow: "#C9C5AB"    // paper
        readonly property color lightYellow: "#D7D1B3"   // card body, inverted text
        readonly property color boxShadow: Qt.rgba(0x7C / 255, 0x7E / 255, 0x6C / 255, 0.69)
        readonly property color textShadow: Qt.rgba(0x7E / 255, 0x7E / 255, 0x74 / 255, 0.57)
        readonly property color alert: "#8F3A30"         // critical states only
    }

    // --- typography (FR-008a) -------------------------------------------------------------
    FontLoader {
        id: mplus
        source: Qt.resolvedUrl("../assets/fonts/MPLUS1[wght].ttf")
    }

    // The game's fonts are used when the owner has them installed; never shipped.
    readonly property string originalBody: findFamily(/rodin/i)
    readonly property string originalTitle: findFamily(/helvetica now micro/i)
    readonly property string bodyFamily: originalBody || mplus.name || "M PLUS 1"
    readonly property string titleFamily: originalTitle || mplus.name || "M PLUS 1"

    function findFamily(re) {
        const all = Qt.fontFamilies();
        for (let i = 0; i < all.length; i++)
            if (re.test(all[i]))
                return all[i];
        return "";
    }

    // One text style: family, size, line height, weight, letter spacing (game px).
    component TextStyle: QtObject {
        property string family
        property real size
        property real lineHeight
        property int weight
        property real letterSpacing
    }

    readonly property Types type: Types {
        body: root.bodyFamily
        title: root.titleFamily
    }
    component Types: QtObject {
        id: types
        property string body
        property string title
        readonly property TextStyle pageHeader: TextStyle { family: types.title; size: 55; lineHeight: 42; weight: Font.Bold; letterSpacing: 3 }
        readonly property TextStyle subheader: TextStyle { family: types.body; size: 27; lineHeight: 27; weight: Font.DemiBold; letterSpacing: 3 }
        readonly property TextStyle headerButton: TextStyle { family: types.body; size: 27; lineHeight: 27; weight: Font.DemiBold; letterSpacing: 3 }
        readonly property TextStyle listButton: TextStyle { family: types.body; size: 27; lineHeight: 27; weight: Font.Medium; letterSpacing: 0 }
        readonly property TextStyle cardHeader: TextStyle { family: types.body; size: 27; lineHeight: 27; weight: Font.Medium; letterSpacing: 2 }
        readonly property TextStyle standard: TextStyle { family: types.body; size: 23; lineHeight: 23; weight: Font.DemiBold; letterSpacing: 1 }
        readonly property TextStyle small: TextStyle { family: types.body; size: 18; lineHeight: 18; weight: Font.Medium; letterSpacing: 2 }
        readonly property TextStyle button: TextStyle { family: types.body; size: 16; lineHeight: 16; weight: Font.DemiBold; letterSpacing: 0 }
    }

    // --- shadows ----------------------------------------------------------------------------
    // Always offset down-right and hard-edged; only `soft` blurs.
    readonly property Shadows shadow: Shadows {}
    component Shadows: QtObject {
        readonly property real textRatio: 0.15            // title shadow offset = 15% of text size (FR-006)
        readonly property real boxX: 3
        readonly property real boxY: 3
        readonly property real softX: 3
        readonly property real softY: 3
        readonly property real softBlur: 4
        readonly property color softColor: Qt.rgba(0, 0, 0, 0.425)
    }

    // --- spacing and sizes (game px at 1080p) ------------------------------------------------
    readonly property Spaces space: Spaces {}
    component Spaces: QtObject {
        readonly property real buttonMargin: 10
        readonly property real pageMarginH: 62
        readonly property real pageMarginV: 39
        readonly property real topPageBodyMargin: 31
        readonly property real bottomPageBodyMargin: 22
        readonly property real tabH: 47
        readonly property real tabW: 214
        readonly property real tabIconGap: 7
        readonly property real square: 22
        readonly property real meterW: 163
        readonly property real meterH: 11
        readonly property real listItemH: 48
        readonly property real listItemGap: 12
        readonly property real railGap: 5                  // rails above/below the selected item
        readonly property real rail: 2
        readonly property real rule: 2
        readonly property real cardW: 538
        readonly property real cardH: 578
        readonly property real cardBodyMarginH: 22
        readonly property real cardBodyGap: 15
        // selector: kite + two small squares at its tip
        readonly property real selectorW: 32
        readonly property real selectorH: 14
        readonly property real selectorHole: 6
        readonly property real selectorDot: 5
        readonly property real selectorDotOffset: 10      // dot centers at ±10 from the axis
        readonly property real selectorGap: 7             // dots → item
    }

    // --- motion -----------------------------------------------------------------------------
    readonly property Motions motion: Motions {}
    component Motions: QtObject {
        readonly property int highlight: 150               // ink sweep (FR-004), calibrate later
        readonly property int touch: 160                   // selected tab's stem down to the rule
        readonly property int untouch: 120                 // the stem back up, when deselected
        readonly property int blink: 240                   // selector blink on move, total (FR-005)
        readonly property int meter: 250                   // meter value change
    }
    // Set by shell.qml while fixtures are active, so screenshots are pixel-identical (SC-002).
    property bool frozen: false

    // --- vignette (FR-002a), measured in the game's menus (design-system §6): ink over the paper
    // on a circle of half the screen's diagonal; clear in the middle (the top and bottom centers
    // stay paper), #A6A18D at the side edges, #8C8978 in the corners.
    readonly property Vignettes vignette: Vignettes {}
    component Vignettes: QtObject {
        readonly property real start: 0.55                 // fractions of half the diagonal
        readonly property real edgeAt: 0.87                // a 16:9 screen's side edges
        readonly property real edgeAlpha: 0.29
        readonly property real cornerAlpha: 0.50
    }

    // Fractional scale per monitor name, set by shell.qml from the compositor adapter.
    property var monitorScales: ({})
    function scaleOf(monitorName: string): real {
        return monitorScales[monitorName] ?? 1;
    }
    // Snap a logical coordinate to the physical pixel grid of a `dpr` display.
    function snap(v: real, dpr: real): real {
        return Math.round(v * dpr) / dpr;
    }
    // A hairline `v` logical px thick, as a whole number of physical pixels (≥ 1), in logical px.
    function hair(v: real, dpr: real): real {
        return Math.max(1, Math.round(v * dpr)) / dpr;
    }

    // --- helpers ----------------------------------------------------------------------------
    // Hairlines: whole pixels, never thinner than 1 (FR-002, SC-008).
    function line(v: real, s: real): int {
        return Math.max(1, Math.round(v * s));
    }
    // Any other length, rounded to whole logical pixels.
    function px(v: real, s: real): int {
        return Math.round(v * s);
    }
}
