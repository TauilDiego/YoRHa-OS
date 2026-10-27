pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"

// Cursor list (design-system §4): the double vertical strips on the left, then a column of
// ListItems with the Selector on the current one. Like the game, there is a single cursor:
// the item at `currentIndex` is drawn "hovered" (ink band + dark selector), and hovering an
// item with the mouse moves the cursor there. Click or Return emits `activated(index)`;
// Up/Down move the cursor while the list has focus.
//   model: a JS array of { label, trailing } (plain strings are accepted as labels).
//   variant: "opaque" | "plain", passed to every ListItem.
// The parent sets the width; items fill what is left after the strips and the selector room.
// spec 003: `focused: false` draws the current item "selected" (its kite light and still, the
// list that lost the focus); `wrap` makes move() go round at the ends; `keysEnabled: false`
// hands the list to its parent: no keys, and hover and clicks only report (hoveredIndex,
// activated) without moving `currentIndex`.
Item {
    id: root

    property real s: 1
    property var model: []
    property int currentIndex: 0
    property string variant: "opaque"
    property bool focused: true
    property bool wrap: false
    property bool keysEnabled: true

    signal activated(int index)
    signal hoveredIndex(int index)

    readonly property int count: Array.isArray(model) ? model.length : 0
    readonly property int stripGap: Tokens.px(Tokens.space.buttonMargin, s)
    readonly property int selectorRoom: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, s)
    readonly property int itemX: strips.implicitWidth + stripGap + selectorRoom
    // Rails stick out above the first and below the last item; keep them inside the strips.
    readonly property int railRoom: Tokens.px(Tokens.space.railGap, s) + Tokens.line(Tokens.space.rail, s)

    implicitWidth: itemX + Tokens.px(defaultItemW, s)
    implicitHeight: column.implicitHeight + 2 * railRoom
    readonly property real defaultItemW: 420                // game px

    function labelOf(entry: var): string {
        return typeof entry === "string" ? entry : String(entry?.label ?? "");
    }

    function trailingOf(entry: var): string {
        return typeof entry === "string" ? "" : String(entry?.trailing ?? "");
    }

    function move(step: int): void {
        if (count <= 0)
            return;
        if (wrap)
            currentIndex = ((currentIndex + step) % count + count) % count;
        else
            currentIndex = Math.max(0, Math.min(count - 1, currentIndex + step));
    }

    Keys.enabled: keysEnabled
    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)
    Keys.onReturnPressed: if (currentIndex >= 0 && currentIndex < count) activated(currentIndex)
    Keys.onEnterPressed: if (currentIndex >= 0 && currentIndex < count) activated(currentIndex)

    Rule {
        id: strips
        s: root.s
        kind: "vertical"
        height: root.height
    }

    Column {
        id: column
        x: root.itemX
        y: root.railRoom
        width: root.width - root.itemX
        spacing: Tokens.px(Tokens.space.listItemGap, root.s)

        Repeater {
            model: root.model

            ListItem {
                required property var modelData
                required property int index

                width: column.width
                s: root.s
                variant: root.variant
                text: root.labelOf(modelData)
                trailing: root.trailingOf(modelData)
                state: index === root.currentIndex ? (root.focused ? "hovered" : "selected") : "normal"

                onHoveredChanged: {
                    if (!hovered)
                        return;
                    root.hoveredIndex(index);
                    if (root.keysEnabled)
                        root.currentIndex = index;
                }
                onClicked: {
                    if (root.keysEnabled)
                        root.currentIndex = index;
                    root.activated(index);
                }
            }
        }
    }
}
