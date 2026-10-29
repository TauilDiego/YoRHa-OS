import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../services"

// The desktop background, one per monitor, on the Wayland background layer behind every window
// (spec 001 US4, spec 004). It shows the wallpaper WallpaperStore resolves for this monitor (a
// scene, by default the game's menu paper, or a picture) and changes it with the transition the
// user picked. `phase` comes from shell.qml, so every monitor breathes together.
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
            elapsed: Math.round(view.elapsed)
        };
    }

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
