pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."
import "../primitives"
import "../base"

// Cursor list (design-system §4): the double vertical strips on the left, then a column of
// ListItems with the Selector on the current one. Like the game, there is a single cursor:
// the item at `currentIndex` is drawn "hovered" (ink band + dark selector), and hovering an
// item with the mouse moves the cursor there. Click or Return emits `activated(index)`;
// Up/Down move the cursor while the list has focus.
//   model: a JS array of { label, trailing, tag } (plain strings are accepted as labels; tag, spec 015:
//   an outline Tag on the row, as ListItem.tag).
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
// U13 (audit D-12): while it scrolls, the strips are a scroll bar (the part in view drawn whole),
// and a tagged row out of view below shows its tag under the column (▼ NEW).
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

    // spec 015: an entry's outline Tag (NEW), "" for none.
    function tagOf(entry: var): string {
        return typeof entry === "string" ? "" : String(entry?.tag ?? "");
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

    // The scroll is kept in rows: the panel changing size (another presentation, another scale)
    // only moves the clamp, never leaves the column scrolled with nothing to hide.
    property int topRow: 0
    readonly property int maxTop: Math.max(0, count - visibleRows)
    readonly property real scrollY: Math.min(topRow, maxTop) * pitch
    property real wheelRest: 0                    // the wheel's turn not yet spent (touchpads)
    function firstRow(): int {
        return Math.min(topRow, maxTop);
    }
    function scrollTo(first: int): void {
        topRow = Math.max(0, Math.min(first, maxTop));
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
    onHeightChanged: Qt.callLater(follow)
    onCountChanged: Qt.callLater(follow)

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
        const before = firstRow();
        scrollTo(first);
        first = firstRow();
        if (first === before)
            return;
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
        // A column that scrolls shows it (audit D-12): the strips are its scroll bar.
        thumbFrom: root.overflows ? root.firstRow() / root.count : 0
        thumbSize: root.overflows ? root.visibleRows / root.count : 1
    }

    // A row out of view below that carries a Tag (NEW on SYSTEM › Updates, spec 015) shows that tag
    // under the column, after a ▼, so the sign can be followed (audit D-12).
    readonly property string tagBelow: {
        if (!overflows)
            return "";
        const last = firstRow() + visibleRows - 1;
        for (let i = last + 1; i < count; i++) {
            const t = tagOf(model[i]);
            if (t !== "")
                return t;
        }
        return "";
    }
    Row {
        id: moreBelow
        x: root.itemX
        y: root.height + Tokens.px(2, root.s)
        spacing: Tokens.px(8, root.s)
        visible: root.tagBelow !== ""
        Shape {
            id: down
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.px(14, root.s)
            height: Tokens.px(9, root.s)
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: Tokens.color.darkGray
                strokeWidth: -1
                startX: 0
                startY: 0
                PathLine { x: down.width; y: 0 }
                PathLine { x: down.width / 2; y: down.height }
                PathLine { x: 0; y: 0 }
            }
        }
        Tag {
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            outline: true
            ink: Tokens.color.darkGray
            text: root.tagBelow
        }
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
                    tag: root.tagOf(modelData)
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
