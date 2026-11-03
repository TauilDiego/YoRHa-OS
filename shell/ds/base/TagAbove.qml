import QtQuick
import Quickshell
import ".."

// spec 015: an outline Tag (NEW) riding above its parent (a tab, a button), placed by one rule so
// every button that carries a badge carries it the same way, at any scale and in any state:
// - vertically, its bottom edge sits Tokens.space.railGap game px above the parent's top edge, as
//   the rails sit above a selected list item (the design system's "ornament riding on an item"
//   gap), rounded to whole physical pixels (at least 1);
// - horizontally (`align`), "right": its right edge flush with the parent's right edge;
//   "center": centered over the parent, the offset rounded to whole physical pixels.
// All offsets are whole physical pixels relative to the parent, so the badge's edges fall on the
// physical grid exactly as the parent's do. It reads nothing from the parent's state, so hover and
// selection never move it. It takes no room in the parent's layout. "" text = hidden.
Item {
    id: root

    property real s: 1
    property string text
    property color ink: Tokens.notify.bandText
    property string align: "right"                   // "right" | "center"

    // The window's monitor decides the snap. QsWindow.window is typed QObject, so go through
    // a `var` (as Rule does).
    readonly property var window: QsWindow.window
    property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")
    readonly property real d: dpr > 0 ? dpr : 1

    // The gap between the badge's bottom edge and the parent's top edge, in logical px.
    readonly property real gap: Math.max(1, Math.round(Tokens.space.railGap * s * d)) / d

    readonly property real hostW: parent ? parent.width : 0

    visible: text !== ""
    width: tag.width
    height: tag.height
    x: align === "center" ? Math.round((hostW - width) / 2 * d) / d : hostW - width
    y: -height - gap

    Tag {
        id: tag
        s: root.s
        dpr: root.d
        outline: true
        ink: root.ink
        text: root.text
    }
}
