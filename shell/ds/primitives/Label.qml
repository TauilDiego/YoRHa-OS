import QtQuick
import ".."

// Text in one of the system's text styles (Tokens.type), scaled by the surface factor `s`.
// `tone` (spec 004 US6): the top bar's tone, 0 paper → 1 light; the default ink follows it.
Text {
    id: root

    property real s: 1
    property string role: "standard"           // a key of Tokens.type
    property bool upper: false
    property real tone: 0

    // The resolved TextStyle and its scaled size (e.g. for shadow offsets).
    readonly property var textStyle: Tokens.type[role] ?? Tokens.type.standard
    readonly property int size: Math.max(1, Tokens.px(textStyle.size, s))

    color: Tokens.hudColor("ink", tone)
    font.family: textStyle.family
    font.pixelSize: size
    font.weight: textStyle.weight
    // M PLUS 1 ships as a variable font; without the axis Qt renders its default (thin) instance.
    font.variableAxes: ({ "wght": textStyle.weight })
    font.letterSpacing: textStyle.letterSpacing * s
    font.capitalization: upper ? Font.AllUppercase : Font.MixedCase
    renderType: Text.NativeRendering             // hinted glyphs stay crisp at small sizes
}
