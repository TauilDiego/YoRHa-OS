pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Option column (spec 003): OptionRows one under the other, without the vertical strips (as in
// the mockup). When they don't fit, the column scrolls with `currentIndex` so the current row —
// its band, rails, shadow and kite — is always in view; the wheel doesn't scroll it.
// The kite hangs in the first selectorRoom px of the list's own width, so nothing is clipped.
//   options: the category's options; values / dims: maps option id → value / dimmed.
//   focused: false → no row is highlighted (the options column without the focus).
Item {
    id: root

    property real s: 1
    property var options: []
    property var values: ({})
    property var dims: ({})
    property int currentIndex: 0
    property bool focused: false

    signal hoveredIndex(int index)
    signal stepped(int index, int dir)
    signal picked(int index, real value)
    signal activated(int index)

    readonly property int selectorRoom: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, s)
    readonly property int railRoom: Tokens.px(Tokens.space.railGap, s) + Tokens.line(Tokens.space.rail, s)
    readonly property int shadowRoom: Tokens.px(Tokens.shadow.boxX, s)
    readonly property int rowH: Tokens.px(Tokens.space.listItemH, s)
    readonly property int pitch: rowH + Tokens.px(Tokens.space.listItemGap, s)
    readonly property int count: options?.length ?? 0

    // The row at `index` (OptionRow), e.g. for its geometry; null when out of range.
    function rowAt(index: int): var {
        return rows.itemAt(index);
    }

    // How many whole rows fit; a parent that wants no partial row sizes the list with fitHeight().
    readonly property int visibleRows: Math.max(1, Math.floor((height - 2 * railRoom + pitch - rowH) / pitch))
    function fitHeight(room: real): int {
        const n = Math.max(1, Math.floor((room - 2 * railRoom + pitch - rowH) / pitch));
        return n * pitch - (pitch - rowH) + 2 * railRoom;
    }

    // Scroll by whole rows, just enough to show row `currentIndex` with its rails.
    property real scrollY: 0
    function follow(): void {
        if (pitch <= 0)                          // still being built
            return;
        let first = Math.round(scrollY / pitch) || 0;
        if (currentIndex < first)
            first = currentIndex;
        else if (currentIndex >= first + visibleRows)
            first = currentIndex - visibleRows + 1;
        first = Math.max(0, Math.min(first, count - visibleRows));
        scrollY = first * pitch;
    }
    onCurrentIndexChanged: follow()
    onHeightChanged: follow()
    onOptionsChanged: {
        scrollY = 0;
        follow();
    }

    // A clipped window on the rows; the column moves up by scrollY (whole rows).
    Item {
        anchors.fill: parent
        clip: true

        Column {
            id: column
            x: root.selectorRoom
            y: root.railRoom - root.scrollY
            width: root.width - x - root.shadowRoom
            spacing: Tokens.px(Tokens.space.listItemGap, root.s)

            Repeater {
                id: rows
                model: root.options

                OptionRow {
                    required property var modelData
                    required property int index

                    width: column.width
                    s: root.s
                    option: modelData
                    value: root.values[modelData?.id] ?? null
                    dimmed: root.dims[modelData?.id] === true
                    focused: root.focused && index === root.currentIndex

                    onHoveredChanged: if (hovered) root.hoveredIndex(index)
                    onStepped: dir => root.stepped(index, dir)
                    onPicked: v => root.picked(index, v)
                    onActivated: root.activated(index)
                }
            }
        }
    }
}
