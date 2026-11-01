pragma ComponentBehavior: Bound

import QtQuick
import ".."

// Option column (spec 003): OptionRows one under the other, without the vertical strips (as in
// the mockup). When they don't fit, the column scrolls with `currentIndex` so the current row —
// its band, rails, shadow and kite — is always in view; the wheel doesn't scroll it.
// The kite hangs in the first selectorRoom px of the list's own width, so nothing is clipped.
//   options: the category's options; values / dims: maps option id → value / dimmed.
//   focused: false → no row is highlighted (the options column without the focus).
// spec 013 (front A): enter(delay, kiteAt) is the cascade over the rows in view (FR-005, as the
// CursorList's). When the options change to another set (another category), the new rows come in
// as the game's sublist (FR-008): hidden when made, then OptionRow.enterLevel, levelStep apart.
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

    // --- spec 013 ------------------------------------------------------------------------------------
    readonly property string motionList: "list"
    property bool leaving: false                 // as the GroupedList's: the window widens
    function enter(delay: int, kiteAt: int): var {
        leaving = false;
        let d = delay, end = 0;
        const first = Math.round(scrollY / Math.max(1, pitch)) || 0;
        for (let i = 0; i < rows.count; i++) {
            const row = rows.itemAt(i) as OptionRow;
            if (!row)
                continue;
            row.enterLevel(0);
            if (i < first || i >= first + visibleRows) {
                row.complete();
                continue;
            }
            end = Math.max(end, row.enter(d, kiteAt));
            d += Tokens.motion.cascadeStep;
        }
        return { next: d, end: end };
    }

    // The ids of the options shown, and of the last set that came in.
    readonly property string optionsKey: (options ?? []).map(o => String(o?.id ?? "")).join("|")
    property string shownKey: ""
    property bool levelArmed: false
    Component.onCompleted: shownKey = optionsKey
    function rowMade(row: OptionRow): void {
        if (shownKey === optionsKey || !visible || Tokens.instant)
            return;
        row.arrive = 0;
        if (!levelArmed) {
            levelArmed = true;
            Qt.callLater(root.levelIn);
        }
    }
    function levelIn(): void {
        levelArmed = false;
        shownKey = optionsKey;
        const first = Math.round(scrollY / Math.max(1, pitch)) || 0;
        let k = 0;
        for (let i = 0; i < rows.count; i++) {
            const row = rows.itemAt(i) as OptionRow;
            if (!row)
                continue;
            if (i < first || i >= first + visibleRows)
                row.enterLevel(0);
            else
                row.enterLevel(k++ * Tokens.motion.levelStep);
        }
    }
    onVisibleChanged: if (!visible) shownKey = optionsKey

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
        width: root.width + (root.leaving ? root.width * Tokens.motion.leaveStretch : 0)
        height: root.height
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

                    Component.onCompleted: root.rowMade(this)
                    onHoveredChanged: if (hovered) root.hoveredIndex(index)
                    onStepped: dir => root.stepped(index, dir)
                    onPicked: v => root.picked(index, v)
                    onActivated: root.activated(index)
                }
            }
        }
    }
}
