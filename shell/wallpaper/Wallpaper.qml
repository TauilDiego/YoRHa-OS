import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../ds/primitives"
import "../services"

// The desktop background (US4, FR-019–FR-021): the menu paper on the Wayland background layer,
// behind every window, one per monitor: the game's menu background (spec 004 US1): paper,
// arcs and diagonal bundles that breathe slowly, and the vignette. No grid, no grain. `phase` comes from shell.qml so every monitor moves together.
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

    PaperDecor {
        anchors.fill: parent
        s: root.s
        phase: root.phase
    }

    Vignette {
        anchors.fill: parent
        enabled: Settings.vignette
    }
}
