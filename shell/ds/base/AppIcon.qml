import QtQuick
import QtQuick.Effects
import ".."
import "../primitives"
import "appicon.js" as AppIconState

// An app's icon (spec 007, contracts/components.md), `size` game px square, in one of three
// styles (the SYSTEM option "App icons", FR-034):
//   ink     the icon redrawn in ink on the paper by shaders/duotone.frag (its luminance picks a
//           color from ink to paper, its alpha is kept); without the compiled .qsb, MultiEffect's
//           colorization in ink, with one warning per shell run;
//   color   the icon as it is;
//   square  the game's square in its place (the mockup's 74 px for a 160 px icon).
// With no `source` it draws `fallback` (the page passes its category's generic icon).
Item {
    id: root

    property real s: 1
    property string source: ""
    property string fallback: ""
    property string style: "ink"                 // "ink" | "color" | "square"
    property real size: Tokens.space.appIconSize

    readonly property string shown: source !== "" ? source : fallback
    readonly property bool shaderOk: duotone.status !== ShaderEffect.Error
    // What is drawn, for a dump: ink, ink-fallback, color, square or none.
    readonly property string drawn: style === "square" ? "square"
        : shown === "" || picture.status === Image.Error ? "none"
        : style === "color" ? "color"
        : shaderOk ? "ink" : "ink-fallback"

    implicitWidth: Tokens.px(size, s)
    implicitHeight: implicitWidth

    Image {
        id: picture
        anchors.fill: parent
        visible: root.style === "color"
        source: root.style === "square" ? "" : root.shown
        sourceSize: Qt.size(Math.ceil(width), Math.ceil(height))
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    ShaderEffect {
        id: duotone
        anchors.fill: parent
        visible: root.style === "ink" && root.shaderOk && picture.status === Image.Ready
        fragmentShader: Qt.resolvedUrl("../../shaders/duotone.frag.qsb")

        property variant source: picture
        property color ink: Tokens.color.darkGray
        property color paper: Tokens.color.lightYellow
    }

    MultiEffect {
        anchors.fill: parent
        visible: root.style === "ink" && !root.shaderOk && picture.status === Image.Ready
        source: visible ? picture : null
        colorization: 1
        colorizationColor: Tokens.color.darkGray
    }

    Square {
        anchors.centerIn: parent
        visible: root.style === "square"
        s: root.s
        size: Math.round(root.size * 0.46)
    }

    onShaderOkChanged: warnFallback()
    Component.onCompleted: warnFallback()

    function warnFallback(): void {
        if (!shaderOk && AppIconState.firstWarning())
            console.warn("app icon: shaders/duotone.frag.qsb is missing (run shaders/build.sh); ink icons use MultiEffect");
    }
}
