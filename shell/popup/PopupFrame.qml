pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../ds/composites"
import "../services"

// The pop-up's look (spec 003, research R1/R5), without the window: ink over the whole area
// (Tokens.color.dim, never blurred) and, centered on it, a paper panel of
// Tokens.space.popupShare of the area, with a hard ink shadow, the page title, a plain rule under
// it, a plain rule over the footer, a text on the footer's left, the key hints on its right and
// the vignette on top. A click on the ink emits dismissed(); clicks on the panel stay there.
// The body (default property) fills the panel; it is laid out in px of a 1612×908 game-px frame
// times `s` = min(panel height / 908, panel width / 1612) × uiScale. On screens taller than 16:9
// the extra height goes above the footer, which stays at the panel's bottom.
// PopupWindow puts it in a window; the gallery shows it as a miniature.
// spec 007: with `tabs` (the pause menu), the panel draws the game's tab bar at y 26 (the tab `tab`
// selected and reaching the dotted rule, the others normal or hovered, no kite), the title at y 127
// with the date and time on its right (`clock`), the plain rule at y 189, and the body starts at
// `bodyTop` (y 221; research R12). A click on a tab emits tabClicked(index). Without tabs, nothing
// changes (the wallpaper picker).
// spec 013 (research R4): `presentation` "floating" (the panel above) or "fullscreen": the panel is
// the whole area, with no ink around it and no shadow. `s` comes from the floating panel in both,
// so the letters keep their size and the floating mode stays as it was (FR-017); the extra room is
// the layouts' (PickerLayout's stretch, front B).
Item {
    id: root

    property string title
    property string subtitle
    property string footerLeft
    property var keys: []
    default property alias content: body.data
    // spec 007
    property var tabs: []                        // [{ label }]
    property int tab: 0
    property bool clock: false
    property int hoveredTab: -1                  // the gallery: a tab drawn hovered without the pointer
    // spec 013
    property string presentation: "floating"     // "floating" | "fullscreen"
    readonly property bool fullscreen: presentation === "fullscreen"
    readonly property bool tabbed: tabs.length > 0
    readonly property int bodyTop: u(tabbed ? Tokens.space.pauseBodyY : 150)

    signal dismissed()
    signal tabClicked(int index)

    readonly property real s: Math.min(shareH / Tokens.space.popupH, shareW / Tokens.space.popupW) * Settings.uiScale
    readonly property Item panel: panelItem

    // Edges on the monitor's physical pixels, as the other surfaces do.
    readonly property var window: QsWindow.window
    readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")
    // The floating panel's size (it sets `s` in both presentations), and the panel's.
    readonly property real shareW: Tokens.snap(width * Tokens.space.popupShare, dpr)
    readonly property real shareH: Tokens.snap(height * Tokens.space.popupShare, dpr)
    // spec 013, front B (FR-013): the panel grows from the floating size to the whole area by `morph`
    // (0 floating, 1 full screen), which follows `presentation` over Tokens.motion.popupFade (at once
    // with Tokens.instant). Switching with the menu open is just this number moving.
    property real morph: fullscreen ? 1 : 0
    Behavior on morph {
        NumberAnimation {
            duration: Tokens.instant ? 0 : Tokens.motion.popupFade
            easing.type: Easing.OutCubic
        }
    }
    readonly property real panelW: Tokens.snap(shareW + (width - shareW) * morph, dpr)
    readonly property real panelH: Tokens.snap(shareH + (height - shareH) * morph, dpr)
    // Wider than 16:9 (the full-screen panel past the width the floating one reaches at 100%), the
    // content stays in a 16:9 band and the extra room is margin: the header, rules, hints and body
    // are inset by it (R4, "limite de largura em ultrawide"). Zero in floating and on 16:9 / 16:10.
    readonly property real fullInset: {
        const d = (width - Math.round(Tokens.px(Tokens.space.popupW, s) / Tokens.space.popupShare)) / 2;
        return d > Tokens.px(4, s) ? Tokens.snap(d, dpr) : 0;
    }
    readonly property real inset: Tokens.snap(fullInset * morph, dpr)

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    // spec 007: where tab `i` is on the screen, { x, y, w, h } (logical px), for tests' clicks.
    function tabGeometry(i: int): var {
        const g = tabBar.tabGeometry(i);
        const p = tabBar.mapToItem(null, 0, 0);
        return { x: g.x, y: Math.round(p.y), w: g.w, h: tabBar.bandH };
    }

    Rectangle {
        anchors.fill: parent
        visible: root.morph < 1
        opacity: 1 - root.morph
        color: Tokens.color.dim
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismissed()
    }

    Item {
        id: panelItem
        x: Tokens.snap((root.width - root.panelW) / 2, root.dpr)
        y: Tokens.snap((root.height - root.panelH) / 2, root.dpr)
        width: root.panelW
        height: root.panelH

        // Footer, measured from the panel's bottom (908 − 820 and 908 − 846 game px).
        readonly property int footerRuleY: height - root.u(Tokens.space.popupH - 820)
        readonly property int footerY: height - root.u(Tokens.space.popupH - 846)

        Rectangle {
            visible: root.morph < 1
            opacity: 1 - root.morph
            x: root.u(Tokens.shadow.popup)
            y: root.u(Tokens.shadow.popup)
            width: parent.width
            height: parent.height
            color: Tokens.color.darkGray
        }

        Rectangle {
            anchors.fill: parent
            color: Tokens.color.darkYellow
        }

        // spec 013, front B: the paper under the full-screen menu, still (phase 0): the arcs and beams
        // of the desktop's background, at the game's size (H/1080). Not made at all while floating.
        Loader {
            anchors.fill: parent
            active: root.morph > 0
            opacity: root.morph
            sourceComponent: PaperDecor {
                s: panelItem.height / 1080
            }
        }

        // Clicks on the paper never reach the ink behind it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        PageHeader {
            id: header
            x: root.inset + root.u(48)
            // With tabs, y 127 is the top of the mockup's 42 px line box (CSS line-height): the
            // taller natural line of the 55 px title is centered on it, so its baseline lands where
            // the mockup's does, 17 px over the rule.
            y: root.tabbed ? root.u(Tokens.space.pauseTitleY) - Math.round((titleText.implicitHeight - root.u(42)) / 2) : root.u(42)
            s: root.s
            title: root.title
            subtitle: root.subtitle
        }

        Rule {
            x: root.inset + root.u(48)
            y: root.u(root.tabbed ? Tokens.space.pauseHRuleY : 112)
            width: parent.width - 2 * x
            s: root.s
        }

        // spec 007: the tab bar (the pause menu); no kite on tabs (the owner's call).
        TabBar {
            id: tabBar
            x: root.inset + root.u(48)
            y: root.u(Tokens.space.pauseTabsY)
            width: parent.width - 2 * x
            visible: root.tabbed
            s: root.s
            tabWidth: Tokens.space.tabW
            model: root.tabs.map((t, i) => ({
                label: t.label,
                state: i === root.tab ? "selected" : i === tabBar.hoveredIndex || i === root.hoveredTab ? "hovered" : "normal"
            }))
            onActivated: index => root.tabClicked(index)
        }

        Label {
            anchors.right: parent.right
            anchors.rightMargin: root.inset + root.u(48)
            y: header.y + header.titleText.y + header.titleText.baselineOffset - baselineOffset
            visible: root.tabbed && root.clock
            s: root.s
            role: "small"
            font.features: ({ "tnum": 1 })
            text: `${Clock.dateText} ${Qt.formatDateTime(Clock.date, "HH:mm")}`
        }

        Rule {
            x: root.inset + root.u(48)
            y: panelItem.footerRuleY
            width: parent.width - 2 * x
            s: root.s
        }

        KeyHints {
            id: hints
            anchors.right: parent.right
            anchors.rightMargin: root.inset + root.u(48)
            y: panelItem.footerY
            s: root.s
            model: root.keys
        }

        Label {
            x: root.inset + root.u(48)
            anchors.verticalCenter: hints.verticalCenter
            s: root.s
            role: "small"
            text: root.footerLeft
            color: Tokens.color.mediumGray
        }

        Item {
            id: body
            x: root.inset
            width: parent.width - 2 * root.inset
            height: parent.height
        }

        Vignette {
            anchors.fill: parent
            s: root.s
            enabled: Settings.vignette
        }
    }
}
