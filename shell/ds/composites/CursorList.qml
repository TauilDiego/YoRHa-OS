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
// spec 013 (FR-005, front A): enter(delay, kiteAt) brings the rows in, one every cascadeStep from
// `delay` ms (ListItem.enter); it returns { next, end }: the delay after its last row, and when the
// last one is complete (ms from now). A menu's frame (PopupFrame) calls it for every list it shows.
// spec 014 (T029, owner 01.11: every menu fits where it belongs and scrolls to hold more): a parent
// that bounds the list sizes it with fitHeight(room) (whole rows only). While the rows don't fit,
// the column scrolls by whole rows with `currentIndex`, as the OptionList's, and the wheel scrolls
// it one row per notch (the cursor, if left out, comes to the nearest row in view: `currentIndex`,
// or `cursorRequested(index)` with keysEnabled: false). A list that fits is drawn as before.
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
    signal cursorRequested(int index)

    readonly property int count: Array.isArray(model) ? model.length : 0
    readonly property int stripGap: Tokens.px(Tokens.space.buttonMargin, s)
    readonly property int selectorRoom: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, s)
    readonly property int itemX: strips.implicitWidth + stripGap + selectorRoom
    // Rails stick out above the first and below the last item; keep them inside the strips.
    readonly property int railRoom: Tokens.px(Tokens.space.railGap, s) + Tokens.line(Tokens.space.rail, s)
    readonly property int shadowRoom: Tokens.px(Tokens.shadow.boxX, s)
    readonly property int rowH: Tokens.px(Tokens.space.listItemH, s)
    readonly property int pitch: rowH + Tokens.px(Tokens.space.listItemGap, s)

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

    readonly property string motionList: "list"
    property bool leaving: false                 // as the OptionList's: the clipped window widens
    function enter(delay: int, kiteAt: int): var {
        leaving = false;
        let d = delay, end = 0;
        const first = firstRow();
        for (let i = 0; i < rows.count; i++) {
            const row = rows.itemAt(i) as ListItem;
            if (!row)
                continue;
            if (i < first || i >= first + visibleRows) {
                row.complete();
                continue;
            }
            end = Math.max(end, row.enter(d, kiteAt));
            d += Tokens.motion.cascadeStep;
        }
        return { next: d, end: end };
    }

    // --- scrolling (spec 014) ----------------------------------------------------------------------
    // How many whole rows fit, and the height that shows `room`'s whole rows (never more than all).
    readonly property int visibleRows: Math.max(1, Math.floor((height - 2 * railRoom + pitch - rowH) / pitch))
    readonly property bool overflows: count > visibleRows
    function fitHeight(room: real): int {
        const n = Math.max(1, Math.min(count, Math.floor((room - 2 * railRoom + pitch - rowH) / pitch)));
        return n * pitch - (pitch - rowH) + 2 * railRoom;
    }

    property real scrollY: 0
    property real wheelRest: 0                    // the wheel's turn not yet spent (touchpads)
    function firstRow(): int {
        return Math.round(scrollY / Math.max(1, pitch)) || 0;
    }
    function scrollTo(first: int): void {
        scrollY = Math.max(0, Math.min(first, count - visibleRows)) * pitch;
    }

    // Just enough whole rows to show row `currentIndex` with its rails.
    function follow(): void {
        if (pitch <= 0)                          // still being built
            return;
        let first = firstRow();
        if (currentIndex < first)
            first = currentIndex;
        else if (currentIndex >= first + visibleRows)
            first = currentIndex - visibleRows + 1;
        scrollTo(first);
    }
    onCurrentIndexChanged: follow()
    onHeightChanged: follow()
    onCountChanged: follow()

    // One wheel notch (120) scrolls one row.
    function wheelBy(delta: real): void {
        if (!overflows)
            return;
        wheelRest += delta;
        let first = firstRow();
        while (wheelRest >= 120) {
            wheelRest -= 120;
            first--;
        }
        while (wheelRest <= -120) {
            wheelRest += 120;
            first++;
        }
        const before = scrollY;
        scrollTo(first);
        if (scrollY === before)
            return;
        first = firstRow();
        if (currentIndex >= first && currentIndex < first + visibleRows)
            return;
        const pick = currentIndex < first ? first : first + visibleRows - 1;
        if (keysEnabled)
            currentIndex = pick;
        else
            cursorRequested(pick);
    }

    // For a dump: the scroll and the rows in view.
    function scrollState(): var {
        const first = firstRow();
        return {
            y: Math.round(scrollY),
            overflows: overflows,
            first: first,
            last: Math.min(count, first + visibleRows) - 1
        };
    }

    WheelHandler {
        enabled: root.overflows
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.wheelBy(event.angleDelta.y)
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

    // The rows' window: clipped only while they don't fit (the kite's room on its left, the shadow's
    // on its right); the column moves up by scrollY (whole rows).
    Item {
        x: strips.implicitWidth + root.stripGap
        width: root.width - x + root.shadowRoom + (root.leaving ? root.width * Tokens.motion.leaveStretch : 0)
        height: root.height
        clip: root.overflows

        Column {
            id: column
            x: root.selectorRoom
            y: root.railRoom - root.scrollY
            width: root.width - root.itemX
            spacing: Tokens.px(Tokens.space.listItemGap, root.s)

            Repeater {
                id: rows
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
}
