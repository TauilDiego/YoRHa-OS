import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../ds/primitives"
import "../services"

// The desktop background (US4, FR-019–FR-021): the menu paper on the Wayland background layer,
// behind every window, one per monitor. Grid, slowly drifting arcs and diagonal bundles, and
// the vignette. `phase` comes from shell.qml so every monitor moves together.
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

    GridBackground {
        anchors.fill: parent
    }

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
