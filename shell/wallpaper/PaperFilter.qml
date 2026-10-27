import QtQuick
import QtQuick.Effects
import "../ds"
import "../ds/primitives"

// The paper filter (spec 004, research R7): a picture's colors pulled toward the paper
// (MultiEffect's colorization, built into Qt) with a softer vignette on top, as in the approved
// mockup. It draws `source` (the picture as laid out, crop included) in its place and hides it;
// `enabled: false` gives the picture back untouched.
Item {
    id: root

    property Item source
    property size textureSize: Qt.size(width, height)    // physical px

    visible: enabled

    ShaderEffectSource {
        id: picture
        sourceItem: root.enabled ? root.source : null
        hideSource: true
        live: true                   // a still picture only renders again when it changes
        textureSize: root.textureSize
    }

    MultiEffect {
        anchors.fill: parent
        source: picture
        colorization: Tokens.wallpaper.filterAmount
        colorizationColor: Tokens.wallpaper.filterTint
    }

    Vignette {
        anchors.fill: parent
        start: Tokens.wallpaper.filterVignetteStart
        edgeAlpha: Tokens.wallpaper.filterVignetteEdge
        cornerAlpha: Tokens.wallpaper.filterVignetteCorner
    }
}
