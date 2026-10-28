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
        // spec 003: ink over the rest of the monitor behind a pop-up (≈55%, never blurred)
        readonly property color dim: Qt.rgba(0x14 / 255, 0x13 / 255, 0x10 / 255, 0.55)
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
        // spec 003: the pop-up panel's hard shadow (ink, over the dimmed desktop)
        readonly property real popup: 6
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
        // spec 003: settings pop-up. The panel is drawn in a 1612×908 game-px frame (84% of
        // 1920×1080) and scaled to popupShare of the monitor.
        readonly property real popupShare: 0.84
        readonly property real popupW: 1612
        readonly property real popupH: 908
        readonly property real settingsCatsW: 300
        readonly property real settingsOptsW: 600
        readonly property real settingsCardW: 440
        readonly property real stepperValueW: 190          // text between ◂ and ▸
        readonly property real sliderW: 220                // editable meter's track
        // --- spec 004: the wallpaper picker's list + preview + options layout (PickerLayout), in
        // the same 1612×908 frame: list at x 48, preview card at 560, Options card at 1160
        readonly property real pickerListW: 380            // list items (after the strips and the kite)
        readonly property real pickerPreviewW: 560
        readonly property real pickerOptionsW: 404
        readonly property real pickerMediaW: 512           // the live preview inside its card
        readonly property real pickerMediaH: 288
        readonly property real pickerOptionScale: 0.815    // option rows' text and values (22/27 px), to fit the card
        // --- end spec 004
    }

    // --- motion -----------------------------------------------------------------------------
    readonly property Motions motion: Motions {}
    component Motions: QtObject {
        readonly property int highlight: 150               // ink sweep (FR-004), calibrate later
        readonly property int touch: 160                   // selected tab's stem down to the rule
        readonly property int untouch: 120                 // the stem back up, when deselected
        readonly property int blink: 240                   // selector blink on move, total (FR-005)
        readonly property int meter: 250                   // meter value change
        // spec 003
        readonly property int popupFade: 150               // pop-up opening fade; closing is instant
        readonly property int actionBusy: 2000             // an action's "in progress" note
    }
    // Set by shell.qml while fixtures are active, so screenshots are pixel-identical (SC-002).
    property bool frozen: false
    // spec 003: reduced motion (set by shell.qml from Settings.reduceMotion). Fades and the
    // selector blink become instant, as they do while frozen.
    property bool reduced: false
    readonly property bool instant: frozen || reduced

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

    // --- spec 004: wallpaper ---------------------------------------------------------------------
    // A scene's paper colors live in its JSON (shell/wallpaper/scenes/); these are what the scene,
    // the paper filter and the transitions draw themselves (values from the approved mockup).
    readonly property Wallpapers wallpaper: Wallpapers {}
    component Wallpapers: QtObject {
        readonly property color darkLine: "#96948C"        // dark scene: arcs and beams (× lineAlpha)
        readonly property color darkVignette: "#000000"    // dark scene: the vignette darkens to black
        readonly property real ruleAlpha: 0.9              // dotted rules over the paper
        readonly property real darkRuleAlpha: 0.55         // dotted rules (darkLine) over the dark paper
        readonly property color dotWeave: Qt.rgba(1, 1, 1, 0.07)   // dark scene: a 1 px dot every 4 px
        readonly property color glint: "#E6E1C8"           // camouflage: the front's flash, the trail's veil
        readonly property real inkSquare: 0.9              // tiles: the ink square before each cell
        // paper filter (research R7): colors pulled toward the paper, a softer vignette on top.
        // MultiEffect's colorization multiplies the picture's luminance by this color, so it is
        // the paper's hue at full brightness (the paper #C9C5AB over its red channel): the light
        // of the picture stays, as with the mockup's "color" blend.
        readonly property color filterTint: "#FFFAD9"
        readonly property real filterAmount: 0.85
        readonly property real filterVignetteStart: 0.5
        readonly property real filterVignetteEdge: 0.26
        readonly property real filterVignetteCorner: 0.35
        // transitions (research R4), in ms
        readonly property int reveal: 1200                 // camouflage: the wave crosses the screen
        readonly property int lead: 200                    // camouflage: refraction ahead of the front
        readonly property int settle: 450                  // camouflage: after the trail, until the end
        readonly property int duration: 900                // wipe, tiles and crossfade (ease in-out)
    }
    // --- end spec 004 ----------------------------------------------------------------------------

    // --- spec 004 US6: the bar over the wallpaper (tone) -------------------------------------------
    // The top bar has no background of its own, so its colors follow the wallpaper under it: the
    // paper tone (today's tokens) over paper, the light tone over the dark scene and dark pictures
    // (spec 004 FR-028, the approved mockup). Components of the bar take `tone` (0 paper → 1 light)
    // and paint each role with hudColor(role, tone).
    //   ink: main text, time, a normal tab's ink, readings' labels · ink2: title, date, values, a
    //   dimmed tab's ink · rest: tab plate, vertical strips · sel / selInk: the selected (and
    //   hovered) tab's plate and ink · track / fill: meter · rule: the dotted rule · alert: critical
    component HudTone: QtObject {
        property color ink
        property color ink2
        property color rest
        property color sel
        property color selInk
        property color track
        property color fill
        property color rule
        property color alert
    }
    readonly property HudTone hudPaper: HudTone {
        ink: root.color.darkGray
        ink2: root.color.mediumGray
        rest: root.color.lightGray
        sel: root.color.darkGray
        selInk: root.color.lightYellow
        track: root.color.lightGray
        fill: root.color.darkGray
        rule: root.color.darkGray
        alert: root.color.alert
    }
    readonly property HudTone hudLight: HudTone {
        ink: Qt.rgba(215 / 255, 209 / 255, 179 / 255, 1)
        // 175,172,161 (was 150,148,140): a dimmed tab keeps 4.5:1 on its plate (004 acabamento)
        ink2: Qt.rgba(175 / 255, 172 / 255, 161 / 255, 1)
        rest: Qt.rgba(215 / 255, 209 / 255, 179 / 255, 0.16)
        sel: Qt.rgba(215 / 255, 209 / 255, 179 / 255, 1)
        selInk: Qt.rgba(78 / 255, 75 / 255, 66 / 255, 1)
        track: Qt.rgba(215 / 255, 209 / 255, 179 / 255, 0.22)
        fill: Qt.rgba(215 / 255, 209 / 255, 179 / 255, 1)
        rule: Qt.rgba(150 / 255, 148 / 255, 140 / 255, 0.75)
        alert: "#C0574A"
    }
    // "Bar contrast: High" (System Settings › Appearance; the owner's P2, 2026-10-27): over paper,
    // every text of the bar (secondary ones too) and the selected tab's plate in a darker ink, and a
    // paper plate (hudHighPlate) behind the texts that have no tab plate. The light tone is the same.
    readonly property color hudHighInk: "#2E2C27"
    readonly property color hudHighPlate: Qt.rgba(0xC9 / 255, 0xC5 / 255, 0xAB / 255, 0.55)
    readonly property HudTone hudPaperHigh: HudTone {
        ink: root.hudHighInk
        ink2: root.hudHighInk
        rest: root.color.lightGray
        sel: root.hudHighInk
        selInk: root.color.lightYellow
        track: root.color.lightGray
        fill: root.color.darkGray
        rule: root.color.darkGray
        alert: root.color.alert
    }
    // Below this mean luma (0–1) of a picture's top band, the bar takes the light tone.
    readonly property real hudLightBelow: 0.45

    // a → b by t (0–1), channel by channel, alpha included (as the mockup's rgba mix). At the ends
    // it returns a or b untouched, so tone 0 paints exactly today's colors.
    function toneMix(a: color, b: color, t: real): color {
        if (!(t > 0))
            return a;
        if (t >= 1)
            return b;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
    // The bar's color for one role (a HudTone property name) at tone t.
    function hudColor(role: string, t: real): color {
        return toneMix(hudPaper[role], hudLight[role], t);
    }
    // The same with the bar's contrast: `high` takes the paper end from hudPaperHigh.
    function hudColorAt(role: string, t: real, high: bool): color {
        return toneMix((high ? hudPaperHigh : hudPaper)[role], hudLight[role], t);
    }
    // --- end spec 004 US6 --------------------------------------------------------------------------
}
