import QtQuick
import "."

// Port of shell/ds/primitives/Label.qml for the SDDM greeter (spec 011, research R3). The login's
// text sizes are the approved mockup's (v3.2), not the shell's type scale, so a Label takes its
// size, weight and letter spacing in game px instead of a `role`. Scaled by the surface factor `s`.
Text {
    id: root

    property real s: 1
    property real size: 21                       // game px
    property int weight: Font.Medium
    property real spacing: 0                     // letter spacing, game px
    property bool upper: false

    readonly property int pixelSize: Math.max(1, Tokens.px(size, s))

    color: Tokens.color.darkGray
    font.family: Tokens.bodyFamily
    font.pixelSize: pixelSize
    font.weight: weight
    // M PLUS 1 ships as a variable font; without the axis Qt renders its default (thin) instance.
    font.variableAxes: ({ "wght": weight })
    font.letterSpacing: spacing * s
    font.capitalization: upper ? Font.AllUppercase : Font.MixedCase
    renderType: Text.NativeRendering             // hinted glyphs stay crisp at small sizes
}
