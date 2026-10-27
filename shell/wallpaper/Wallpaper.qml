import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../services"

// The desktop background, one per monitor, on the Wayland background layer behind every window
// (spec 001 US4, spec 004). It shows the wallpaper WallpaperStore resolves for this monitor: a
// scene (the default is the game's menu paper, spec 004 US1) or a picture. `phase` comes from
// shell.qml, so every monitor breathes together.
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
    WlrLayershell.namespace: "rien-wallpaper"
    color: Tokens.color.darkYellow

    readonly property real s: height / 1080 * Settings.uiScale
    readonly property string monitorName: modelData?.name ?? ""
    readonly property real dpr: Tokens.scaleOf(monitorName)
    readonly property string current: WallpaperStore.resolve(monitorName)

    // For `wallpaper dump` (contracts/ipc.md).
    function dumpEntry(): var {
        return {
            name: monitorName,
            current: current,
            own: WallpaperStore.monitors[monitorName] ?? "",
            transitioning: false,
            kind: WallpaperStore.transition.kind,
            elapsed: 0
        };
    }

    WallpaperView {
        anchors.fill: parent
        wallpaper: WallpaperCatalog.byId(root.current)
        s: root.s
        phase: root.phase
        screenSize: Qt.size(Math.round(root.width * root.dpr), Math.round(root.height * root.dpr))
    }
}
