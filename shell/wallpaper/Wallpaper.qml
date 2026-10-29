import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../services"

// The desktop background, one per monitor, on the Wayland background layer behind every window
// (spec 001 US4, spec 004). It shows the wallpaper WallpaperStore resolves for this monitor (a
// scene, by default the game's menu paper, or a picture) and changes it with the transition the
// user picked. `phase` comes from shell.qml, so every monitor breathes together.
// spec 004 US6: it also sets the tone of this monitor's bar (WallpaperStore.toneMix), which
// follows the wallpaper and turns while a change covers the bar's band.
PanelWindow {
    id: root

    property var modelData                       // the ShellScreen, from Variants
    property real phase: 0
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "yorha-wallpaper"
    color: Tokens.color.darkYellow

    readonly property real s: height / 1080 * Settings.uiScale
    readonly property string monitorName: modelData?.name ?? ""

    // For `wallpaper dump` (contracts/ipc.md).
    function dumpEntry(): var {
        return {
            name: monitorName,
            current: view.current,
            own: WallpaperStore.monitors[monitorName] ?? "",
            transitioning: view.running,
            kind: view.running ? view.runKind : WallpaperStore.transition.kind,
            elapsed: Math.round(view.elapsed),
            luma: lumaOf(view.current)                   // spec 004 US6
        };
    }

    // --- spec 004 US6: the bar's tone on this monitor ------------------------------------------------
    // Still: the tone of the wallpaper on screen. During a change: from the tone the bar had when it
    // started (an interrupted change's still frame included) to the new one, by smoothstep of how
    // much of the bar's band the change covers. While the new picture loads, or its luma is not
    // known yet, the bar keeps its tone. Instant changes (fixtures, reduced motion) have no
    // animation, so the tone just switches.
    readonly property real shownTone: WallpaperStore.toneOf(view.shownItem)
    readonly property real incomingTone: WallpaperStore.toneOf(view.incomingItem)
    property real tone: 0
    property real fromTone: 0

    function lumaOf(id: string): var {
        const w = WallpaperCatalog.byId(id);
        if (w?.type !== "image")
            return null;
        const l = WallpaperCatalog.lumaOf(w.path, !WallpaperStore.paperFilterOff.includes(w.path));
        return l < 0 ? null : l;
    }

    function syncTone(): void {
        let t;
        if (view.animating && !view.freezing) {
            const to = incomingTone < 0 ? fromTone : incomingTone;
            const c = Math.max(0, Math.min(1, view.topProgress));
            t = fromTone + (to - fromTone) * c * c * (3 - 2 * c);
        } else if (view.running || shownTone < 0) {
            return;                                      // paused for a grab, loading, unmeasured
        } else {
            t = shownTone;
        }
        tone = t;
        WallpaperStore.setToneMix(monitorName, t);
    }
    onShownToneChanged: syncTone()
    onIncomingToneChanged: syncTone()
    onMonitorNameChanged: syncTone()
    Component.onCompleted: syncTone()
    Connections {
        target: view
        function onBegun(): void {
            root.fromTone = root.tone;
            root.syncTone();
        }
        function onTopProgressChanged(): void {
            root.syncTone();
        }
        function onRunningChanged(): void {
            root.syncTone();
        }
        function onAnimatingChanged(): void {
            root.syncTone();
        }
    }
    // --- end spec 004 US6 --------------------------------------------------------------------------

    WallpaperTransition {
        id: view
        anchors.fill: parent
        current: WallpaperStore.resolve(root.monitorName)
        s: root.s
        phase: root.phase
        dpr: Tokens.scaleOf(root.monitorName)
        kind: WallpaperStore.transition.kind
        cell: WallpaperStore.transition.cell
        trail: WallpaperStore.transition.trail
        glitch: WallpaperStore.transition.glitch
        instant: WallpaperStore.instant
        paperFilterOff: WallpaperStore.paperFilterOff
    }
}
