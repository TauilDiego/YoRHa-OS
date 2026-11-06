pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
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
// spec 013, front A: the game's motion, with `motion: true` (PopupWindow; a gallery miniature stays
// still). `anim` says what runs: "idle" | "opening" | "assembling" | "tab" | "closing".
//   open()   (FR-009) the ink around the panel fades in over openDim; on the panel, the light grid
//            (openGrid), then the triangles turn to paper (openTris, TriangleReveal); then the
//            content builds itself in the game's order, timed by `openT`: the rules draw, the tab
//            bar's strips and tabs fade in, the title types (PageHeader), the cards fade in, the
//            rows cascade (every motion list and row in the body, walked in order: enter()), the
//            footer slides in and the kites come in.
//   close(leave)  the live row stretches and the others fade first (leave: an action that leaves
//            the menu, FR-008), then the triangles take the panel away (closeTris) and the ink
//            fades; `closing` stays true until then (PopupWindow keeps the frame shown).
//   tab      (FR-006) a new `tab`: the old page fades (`swapFrom`, `swapLevel`, tabOut), the body
//            stays empty (tabGap; `swapHold` hides the new page), then its rows cascade. The
//            host (PauseMenu) binds its pages to those three. A new tab meanwhile restarts the gap
//            and keeps the fading page. During the triangles there is no swap: the new page just
//            builds in the old one's place.
//   footer   (FR-007) new hints or a new footer text come in whole, blurred and faint, sliding
//            footDx from the left; after a tab change, once the new page mounts.
// With Tokens.instant everything is at its final state at once (FR-016).
Item {
    id: root

    property string title
    property string subtitle
    property string footerLeft
    property var keys: []
    default property alias content: body.data
    // spec 007
    property var tabs: []                        // [{ label, tag }] (tag: spec 015, optional)
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

    // --- spec 013, front A: the motion ---------------------------------------------------------------
    property bool motion: false
    readonly property string anim: closing ? "closing"
        : opening ? (openT < trisEnd ? "opening" : "assembling")
        : swapHold || tabBusy || header.busy ? "tab" : "idle"

    // Opening: one clock from open(), ms. Until trisEnd the grid and the triangles; then `buildT`
    // runs the assembly (Tokens.motion.build*), and `level` says how far a part is into it.
    property bool opening: false
    property real openT: 0
    property int trisEnd: 0
    property bool footBuilt: true
    readonly property real buildT: opening ? Math.max(0, openT - trisEnd) : -1
    function level(start: real, dur: real): real {
        return buildT < 0 ? 1 : Math.max(0, Math.min(1, (buildT - start) / Math.max(1, dur)));
    }
    readonly property real ruleDrawn: 1 - Math.pow(1 - level(0, Tokens.motion.buildRules), 4)

    // Closing: its own clock, ms; the triangles start after the leaving row.
    property bool closing: false
    property real closeT: 0
    property int leaveMs: 0

    // The ink around the floating panel.
    readonly property real dimLevel: closing ? 1 - Math.max(0, Math.min(1, (closeT - leaveMs) / Math.max(1, Tokens.motion.closeTris)))
        : opening ? Math.min(1, openT / Math.max(1, Tokens.motion.openDim)) : 1

    function open(): void {
        openClock.stop();
        firstFrame.stop();
        closeClock.stop();
        closing = false;
        swapReset();
        footReset();
        if (!motion)
            return;
        if (Tokens.instant) {
            opening = false;
            header.settle();
            Qt.callLater(root.completeBody);
            return;
        }
        trisEnd = reveal.ok ? Tokens.motion.openGrid + Tokens.motion.openTris : 0;
        reveal.seed = Math.floor(Math.random() * 100000);
        openT = 0;
        opening = true;
        footBuilt = false;
        header.hold();
        // The clock starts with the window's first frame (making the menu takes a frame or more).
        firstFrame.restart();
    }
    // The third tick: the first frames are out and shown (making them can take a while: the shader,
    // the texture, the compositor mapping the surface), so no part of the grid is spent before it
    // shows. In the lab VM the grid still shows for 60–150 ms (its first frames come irregularly).
    // U13: a pop-up kept made while hidden (the pause menu) may get a tick at once, in the same event
    // as the open, from a frame drawn before it showed; only ticks after that count.
    FrameAnimation {
        id: firstFrame
        property int ticks: 0
        property real startedAt: 0
        onRunningChanged: if (running) {
            ticks = 0;
            startedAt = Date.now();
        }
        onTriggered: {
            if (Date.now() - startedAt < 2)
                return;
            if (++ticks < 3)
                return;
            stop();
            root.startOpen();
        }
    }
    function startOpen(): void {
        if (!opening || closing)
            return;
        const titleEnd = header.typeIn(trisEnd + Tokens.motion.buildTitle);
        runOpenClock(Math.max(trisEnd + Tokens.motion.buildEnd, titleEnd));
        // After this event: the host may still be putting its pages back (PauseMenu.restart).
        Qt.callLater(root.buildBody);
    }
    function runOpenClock(total: int): void {
        openClock.stop();
        openClock.from = openT;
        openClock.to = total;
        openClock.duration = Math.max(1, total - openT);
        openClock.start();
    }
    function buildBody(): void {
        if (!opening)
            return;
        const at = trisEnd + Tokens.motion.buildBody - openT;
        const end = enterBody(Math.max(0, at), Math.max(0, trisEnd + Tokens.motion.buildKite - openT));
        if (openT + end > openClock.to)
            runOpenClock(openT + end);
    }
    NumberAnimation {
        id: openClock
        target: root
        property: "openT"
        onFinished: root.opening = false
    }
    onOpenTChanged: {
        if (opening && !footBuilt && buildT >= Tokens.motion.buildFoot) {
            footBuilt = true;
            footIn(0);
        }
    }

    function close(leave: bool): void {
        openClock.stop();
        firstFrame.stop();
        swapReset();
        if (Tokens.instant || !motion) {
            closing = false;
            opening = false;
            return;
        }
        leaveMs = leave ? Tokens.motion.leave : 0;
        if (leave)
            leaveBody();
        reveal.seed = Math.floor(Math.random() * 100000);
        closeT = 0;
        closing = true;
        closeClock.to = leaveMs + (reveal.ok ? Tokens.motion.closeTris : 0);
        closeClock.duration = Math.max(1, closeClock.to);
        closeClock.start();
    }
    NumberAnimation {
        id: closeClock
        target: root
        property: "closeT"
        from: 0
        onFinished: {
            root.closing = false;
            root.opening = false;
        }
    }

    // The body's motion rows and lists, in order (only the shown ones). visit(item) returns true
    // when it took care of the item and its children.
    function walk(item, visit): void {
        if (!item || !item.visible)
            return;
        if (visit(item))
            return;
        const kids = item.children;
        for (let i = 0; i < kids.length; i++)
            walk(kids[i], visit);
    }
    // The cascade from `delay` ms (FR-005); kiteAt ≥ 0 brings the kites in then. Returns when the
    // last row is complete (ms from now).
    function enterBody(delay: int, kiteAt: int): int {
        let d = delay, end = 0;
        walk(body, it => {
            if (it.motionList !== undefined) {
                const r = it.enter(d, kiteAt);
                d = r.next;
                end = Math.max(end, r.end);
                return true;
            }
            if (it.motionRow !== undefined) {
                end = Math.max(end, it.enter(d, kiteAt));
                d += Tokens.motion.cascadeStep;
                return true;
            }
            return false;
        });
        return end;
    }
    function completeBody(): void {
        walk(body, it => {
            if (it.motionRow !== undefined) {
                it.complete();
                return true;
            }
            if (it.motionList !== undefined) {
                it.enter(0, -1);
                return true;
            }
            return false;
        });
    }
    function leaveBody(): void {
        walk(body, it => {
            if (it.motionRow !== undefined) {
                it.leave();
                return true;
            }
            if (it.motionList !== undefined)
                it.leaving = true;
            return false;
        });
    }

    // Tab change (FR-006).
    property int shownTab: tab
    property int swapFrom: -1
    property real swapLevel: 1
    property bool swapHold: false
    property bool tabBusy: false
    property real mountAt: 0
    onTabChanged: {
        const from = shownTab;
        shownTab = tab;
        if (!motion || !tabbed || from === tab || Tokens.instant || closing)
            return;
        if (opening && openT < trisEnd + Tokens.motion.buildBody) {
            // Nothing of the body shows yet: the new page builds in the old one's place.
            Qt.callLater(root.buildBody);
            return;
        }
        if (!swapHold) {
            swapFrom = from;
            swapOut.restart();
        }
        swapHold = true;
        tabBusy = true;
        mountAt = Date.now() + Tokens.motion.tabOut + Tokens.motion.tabGap;
        mountAnim.stop();
        mountAnim.start();
    }
    NumberAnimation {
        id: swapOut
        target: root
        property: "swapLevel"
        from: 1
        to: 0
        duration: Tokens.motion.tabOut
    }
    // The mount on a frame, as the rest of the motion (a timer could land a frame late).
    SequentialAnimation {
        id: mountAnim
        PauseAnimation { duration: Tokens.motion.tabOut + Tokens.motion.tabGap }
        ScriptAction { script: root.mount() }
    }
    function mount(): void {
        swapFrom = -1;
        swapHold = false;
        const end = enterBody(0, -1);
        busyTimer.interval = Math.max(1, end);
        busyTimer.restart();
    }
    Timer {
        id: busyTimer
        onTriggered: root.tabBusy = false
    }
    function swapReset(): void {
        swapOut.stop();
        mountAnim.stop();
        busyTimer.stop();
        swapFrom = -1;
        swapLevel = 1;
        swapHold = false;
        tabBusy = false;
        shownTab = tab;
    }

    // Footer (FR-007): `footP` the fade and blur (footFade), `footQ` the slide (footSlide, OutQuart).
    property real footP: 1
    property real footQ: 1
    property string footSig: ""
    readonly property real footOpacity: (footP < 0.5 ? 0.28 + 0.57 * footP / 0.5 : 0.85 + 0.15 * (footP - 0.5) / 0.5)
        * (opening && !footBuilt ? 0 : 1)
    readonly property real footBlur: footP >= 1 ? 0 : footP < 0.5 ? 3 - 2 * footP / 0.5 : 1 - (footP - 0.5) / 0.5
    function footIn(delay: int): void {
        footAnim.stop();
        if (Tokens.instant || !motion) {
            footReset();
            return;
        }
        footP = 0;
        footQ = 0;
        footPause.duration = Math.max(0, delay);
        footAnim.start();
    }
    function footReset(): void {
        footAnim.stop();
        footP = 1;
        footQ = 1;
        footSig = JSON.stringify([footerLeft, keys]);
    }
    function footCheck(): void {
        const sig = JSON.stringify([footerLeft, keys]);
        if (sig === footSig)
            return;
        footSig = sig;
        if (!motion || Tokens.instant || closing || (opening && !footBuilt))
            return;
        footIn(swapHold ? Math.max(0, mountAt - Date.now()) : 0);
    }
    onKeysChanged: Qt.callLater(root.footCheck)
    onFooterLeftChanged: Qt.callLater(root.footCheck)
    SequentialAnimation {
        id: footAnim
        PauseAnimation { id: footPause }
        ParallelAnimation {
            NumberAnimation { target: root; property: "footP"; from: 0; to: 1; duration: Tokens.motion.footFade }
            NumberAnimation { target: root; property: "footQ"; from: 0; to: 1; duration: Tokens.motion.footSlide; easing.type: Easing.OutQuart }
        }
    }

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
        return { x: g.x, y: Math.round(p.y), w: g.w, h: tabBar.bandH, tag: g.tag, tagBox: g.tagBox ?? null };    // tag: spec 015
    }

    Rectangle {
        anchors.fill: parent
        visible: root.morph < 1
        opacity: root.dimLevel * (1 - root.morph)   // spec 013: A's dim level, B's morph to full screen
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
            animated: root.motion                // spec 013 (FR-004)
        }

        // spec 013: the rules draw themselves from the left while the menu assembles.
        Item {
            x: root.inset + root.u(48)
            y: root.u(root.tabbed ? Tokens.space.pauseHRuleY : 112)
            width: Math.round((parent.width - 2 * x) * root.ruleDrawn)
            height: titleRule.implicitHeight
            clip: root.ruleDrawn < 1
            visible: root.ruleDrawn > 0

            Rule {
                id: titleRule
                width: panelItem.width - 2 * parent.x
                s: root.s
            }
        }

        // spec 007: the tab bar (the pause menu); no kite on tabs (the owner's call).
        TabBar {
            id: tabBar
            x: root.inset + root.u(48)
            // On the physical grid (spec 015): at a half physical px the selected tab's clipped
            // plate and a resting tab's band round their top edge apart (1 px at 1.5), and the NEW
            // badge above SYSTEM would seem to move when the tab is selected.
            y: Tokens.snap(root.u(Tokens.space.pauseTabsY), root.dpr)
            width: parent.width - 2 * x
            visible: root.tabbed
            s: root.s
            tabWidth: Tokens.space.tabW
            pulse: root.motion                   // spec 013 (FR-002)
            buildT: root.buildT
            model: root.tabs.map((t, i) => ({
                label: t.label,
                tag: t.tag ?? "",
                state: i === root.tab ? "selected" : i === tabBar.hoveredIndex || i === root.hoveredTab ? "hovered" : "normal"
            }))
            onActivated: index => root.tabClicked(index)
        }

        Label {
            anchors.right: parent.right
            anchors.rightMargin: root.inset + root.u(48)
            y: header.y + header.titleText.y + header.titleText.baselineOffset - baselineOffset
            visible: root.tabbed && root.clock
            opacity: root.level(Tokens.motion.buildTitle, Tokens.motion.buildBodyFade)    // spec 013
            s: root.s
            role: "small"
            font.features: ({ "tnum": 1 })
            text: `${Clock.dateText} ${Qt.formatDateTime(Clock.date, "HH:mm")}`
        }

        Item {
            x: root.inset + root.u(48)
            y: panelItem.footerRuleY
            width: Math.round((parent.width - 2 * x) * root.ruleDrawn)
            height: footRule.implicitHeight
            clip: root.ruleDrawn < 1
            visible: root.ruleDrawn > 0

            Rule {
                id: footRule
                width: panelItem.width - 2 * parent.x
                s: root.s
            }
        }

        // spec 013 (FR-007): the hints and the footer's text, together, so they come in as one.
        Item {
            id: footer
            y: panelItem.footerY
            width: parent.width
            height: hints.implicitHeight
            opacity: root.footOpacity
            transform: Translate { x: -Math.round((1 - root.footQ) * Tokens.motion.footDx * root.s) }
            layer.enabled: root.footBlur > 0
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 16
                blur: Math.min(1, root.footBlur * 2 * root.s / 16)
            }

            KeyHints {
                id: hints
                anchors.right: parent.right
                anchors.rightMargin: root.inset + root.u(48)
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
        }

        Item {
            id: body
            x: root.inset
            width: parent.width - 2 * root.inset
            height: parent.height
            opacity: root.level(Tokens.motion.buildBody, Tokens.motion.buildBodyFade)   // spec 013
        }

        Vignette {
            anchors.fill: parent
            s: root.s
            enabled: Settings.vignette
        }
    }

    // spec 013 (FR-009): the grid and the triangles over the panel (and, floating, its shadow).
    TriangleReveal {
        id: reveal
        x: panelItem.x
        y: panelItem.y
        width: panelItem.width + (root.fullscreen ? 0 : root.u(Tokens.shadow.popup))
        height: panelItem.height + (root.fullscreen ? 0 : root.u(Tokens.shadow.popup))
        panelW: panelItem.width
        panelH: panelItem.height
        target: panelItem
        s: root.s
        dpr: root.dpr
        mode: root.closing ? (root.closeT >= root.leaveMs ? "close" : "off")
            : root.opening && root.openT < root.trisEnd ? (root.openT < Tokens.motion.openGrid ? "grid" : "open") : "off"
        elapsed: root.closing ? root.closeT - root.leaveMs : root.openT - (root.openT < Tokens.motion.openGrid ? 0 : Tokens.motion.openGrid)
        duration: root.closing ? Tokens.motion.closeTris : root.openT < Tokens.motion.openGrid ? Tokens.motion.openGrid : Tokens.motion.openTris
    }
}
