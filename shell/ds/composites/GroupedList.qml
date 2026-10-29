pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"

// Grouped list (spec 004): the CursorList with group titles, as in the wallpaper picker's mockup.
// `model` is a JS array of entries, in order:
//   { group: "SCENES" }          a title (small, medium-gray, aligned with the items); no cursor;
//   { note: "…" }                a line under a title (e.g. where to put pictures); no cursor;
//   { label, trailing, dim }     an item: a ListItem with the kite. `trailing` is a mark on its right
//                                in small text ("● ALL"); a `dim` item is drawn dimmed and still
//                                takes the cursor (then its text is light at 55% on the band).
// `currentIndex` counts items only. As in the CursorList (spec 003): `focused: false` draws the
// current item "selected" (its kite light and still); `wrap` makes move() go round; with
// `keysEnabled: false` the parent drives it: no keys, and hover and clicks only report
// (hoveredIndex, activated) without moving `currentIndex`.
// The parent sets the size. Taller content scrolls at once, by whole entries, so the current item
// with its rails (and its group's title, when it is the group's first) is always in view.
// spec 007 (T043): the view's top always stops at an entry's top (less the rails' room, inside the
// wider gap above it), so the first visible entry is never cut, whether the cursor or the wheel
// scrolled it. The bottom too (T043, second part): while the list overflows, the window ends under
// the last entry that fits whole, so the last visible line is never cut
// either; the paper under it stays empty. The wheel scrolls one
// entry per notch, only when the content is taller than the list (otherwise it does nothing, as
// before); a cursor scrolled out of view comes back to the nearest whole item in view (moved here
// with `keysEnabled`, asked for by `cursorRequested(index)` otherwise). `scrollState()` tells it.
// spec 007: `search` ({ query, count } or null) puts the SearchHeader on top, where the group
// titles would be (the model then has no titles); `emptyText`, with no item, is a line in
// medium-gray in place of the items; `trailingRole` is the role of the items' trailing text.
Item {
    id: root

    property real s: 1
    property var model: []
    property int currentIndex: 0
    property string variant: "opaque"
    property bool focused: true
    property bool wrap: true
    property bool keysEnabled: true
    property var search: null                    // spec 007
    property string emptyText: ""
    property string trailingRole: "small"

    signal activated(int index)
    signal hoveredIndex(int index)
    signal cursorRequested(int index)             // the wheel left the cursor out of view (spec 007)

    readonly property var modelEntries: Array.isArray(model) ? model : []
    readonly property bool noItems: !modelEntries.some(e => isItem(e))
    readonly property var entries: (search ? [{ searchLine: true }] : []).concat(modelEntries,
        noItems && emptyText !== "" ? [{ emptyLine: emptyText }] : [])
    // For each entry, its item index (-1 for titles and notes); and each item's entry index.
    readonly property var itemOf: {
        const out = [];
        let n = 0;
        for (const e of entries)
            out.push(isItem(e) ? n++ : -1);
        return out;
    }
    readonly property var entryOf: {
        const out = [];
        itemOf.forEach((it, i) => {
            if (it >= 0)
                out.push(i);
        });
        return out;
    }
    readonly property int count: entryOf.length

    readonly property int stripGap: Tokens.px(Tokens.space.buttonMargin, s)
    readonly property int selectorRoom: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, s)
    readonly property int railRoom: Tokens.px(Tokens.space.railGap, s) + Tokens.line(Tokens.space.rail, s)
    readonly property int shadowRoom: Tokens.px(Tokens.shadow.boxX, s)
    readonly property int itemX: strips.implicitWidth + stripGap + selectorRoom
    readonly property int groupTop: Tokens.px(10, s)         // a title's room above (not the first one's)
    readonly property int groupBottom: Tokens.px(2, s)
    // A first entry that is an item keeps its rails inside.
    readonly property int topRoom: count > 0 && entryOf[0] === 0 ? railRoom : 0
    readonly property int contentHeight: topRoom + Math.ceil(column.implicitHeight) + railRoom

    implicitWidth: itemX + Tokens.px(Tokens.space.pickerListW, s) + shadowRoom
    implicitHeight: contentHeight

    function isItem(e: var): bool {
        return e !== null && typeof e === "object" && e.group === undefined && e.note === undefined
            && e.searchLine === undefined && e.emptyLine === undefined;
    }

    // The entry object of item `index` (null when out of range).
    function itemData(index: int): var {
        return entries[entryOf[index]] ?? null;
    }

    // Entry `i`'s delegate (typed var, so its own properties can be read).
    function entryAt(i: int): var {
        return rows.itemAt(i);
    }

    // Item `index`'s ListItem, e.g. for its geometry; null when out of range.
    function itemAt(index: int): var {
        return entryAt(entryOf[index] ?? -1)?.row ?? null;
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

    // --- scrolling -----------------------------------------------------------------------------------
    property real scrollY: 0
    readonly property bool overflows: contentHeight > height
    property real wheelRest: 0                    // the wheel's turn not yet spent (touchpads)

    // Entry `i`'s top, in content px.
    function entryTop(i: int): real {
        const r = rows.itemAt(i);
        return r ? topRoom + r.y : 0;
    }

    // Where the view may stop, in content px and ascending: each entry's top less the rails' room
    // (the gap between entries is wider, so nothing of the entry above shows), never under 0.
    function stops(): var {
        const out = [];
        for (let i = 0; i < entries.length; i++)
            out.push(Math.max(0, entryTop(i) - railRoom));
        return out;
    }

    // The highest stop at or above `v`, and the lowest at or below it.
    function stopAbove(v: real): real {
        let best = 0;
        for (const p of stops())
            if (p <= v + 0.5)
                best = Math.max(best, p);
        return best;
    }
    function stopBelow(v: real): real {
        const all = stops();
        for (const p of all)
            if (p >= v - 0.5)
                return p;
        return all.length > 0 ? all[all.length - 1] : 0;
    }

    // The last stop: the first one that shows the content's end.
    function maxScroll(): real {
        return overflows ? stopBelow(contentHeight - height) : 0;
    }

    // Item `index`'s span that must be in view, in content px: from its group's title (titles and
    // notes right above the item) to its bottom rail; null when out of range.
    function spanOf(index: int): var {
        const e = entryOf[index];
        const row = rows.itemAt(e ?? -1);
        if (!row)
            return null;
        let first = e;
        while (first > 0 && itemOf[first - 1] < 0)
            first--;
        const above = rows.itemAt(first);
        return {
            a: topRoom + (first < e && above ? above.y : row.y - railRoom),
            b: topRoom + row.y + row.height + railRoom
        };
    }

    function follow(): void {
        const span = spanOf(currentIndex);
        if (!span || height <= 0) {
            scrollY = 0;
            return;
        }
        let y = stopAbove(scrollY);
        if (span.a < y)
            y = stopAbove(span.a);
        else if (span.b > y + height)
            y = stopBelow(span.b - height);
        scrollY = Math.max(0, Math.min(y, maxScroll()));
    }

    // One wheel notch (120) scrolls one entry; the cursor, if left out, comes to the nearest whole
    // item in view.
    function wheelBy(delta: real): void {
        if (!overflows)
            return;
        wheelRest += delta;
        let y = scrollY;
        const all = stops();
        while (wheelRest >= 120) {
            wheelRest -= 120;
            y = all.filter(p => p < y - 0.5).reduce((m, p) => Math.max(m, p), 0);
        }
        while (wheelRest <= -120) {
            wheelRest += 120;
            y = Math.min(maxScroll(), all.find(p => p > y + 0.5) ?? maxScroll());
        }
        if (y === scrollY)
            return;
        scrollY = y;
        const span = spanOf(currentIndex);
        if (span && span.a >= y - 0.5 && span.b <= y + height + 0.5)
            return;
        const down = !span || span.a < y;
        let pick = -1;
        for (let i = 0; i < count; i++) {
            const s2 = spanOf(i);
            if (!s2 || s2.a < y - 0.5 || s2.b > y + height + 0.5)
                continue;
            pick = i;
            if (down)
                break;
        }
        if (pick < 0)
            return;
        if (keysEnabled)
            currentIndex = pick;
        else
            cursorRequested(pick);
    }

    // The window's height: the whole list's while nothing scrolls; when it overflows, down to the
    // bottom of the last entry that fits whole from `scrollY`, plus the rails' room (up to the
    // list's own height: an entry whose rails don't fit is still whole, as before).
    function visibleHeight(): real {
        if (!overflows)
            return height;
        let h = 0;
        for (let i = 0; i < entries.length; i++) {
            const r = rows.itemAt(i);
            if (!r)
                continue;
            const end = topRoom + r.y + r.height - scrollY;
            if (end > height + 0.5)
                break;
            if (end > 0)
                h = Math.min(height, end + railRoom);
        }
        return h > 0 ? h : height;
    }
    readonly property real viewHeight: {
        scrollY;
        height;
        contentHeight;
        entries;
        return visibleHeight();
    }

    // For a dump: the scroll, the first and last entries in view and whether either is cut.
    function scrollState(): var {
        const h = visibleHeight();
        let first = -1, last = -1;
        for (let i = 0; i < entries.length; i++) {
            const r = rows.itemAt(i);
            if (!r)
                continue;
            const top = topRoom + r.y, bottom = top + r.height;
            if (first < 0 && bottom > scrollY + 0.5)
                first = i;
            if (top < scrollY + h - 0.5)
                last = i;
        }
        const lr = rows.itemAt(last);
        return {
            y: Math.round(scrollY),
            overflows: overflows,
            first: first,
            cut: first >= 0 && entryTop(first) < scrollY - 0.5,
            last: last,
            cutBottom: !!lr && topRoom + lr.y + lr.height > scrollY + h + 0.5
        };
    }

    WheelHandler {
        enabled: root.overflows
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.wheelBy(event.angleDelta.y)
    }

    onCurrentIndexChanged: Qt.callLater(follow)
    onHeightChanged: Qt.callLater(follow)
    onModelChanged: Qt.callLater(follow)

    Rule {
        id: strips
        s: root.s
        kind: "vertical"
        height: Math.min(root.height, root.contentHeight)
    }

    // A clipped window on the entries, with the kite's room on its left and the shadow's on its right.
    Item {
        x: strips.implicitWidth + root.stripGap
        width: root.width - x
        height: root.viewHeight
        clip: true

        Column {
            id: column
            x: root.selectorRoom
            y: root.topRoom - root.scrollY
            width: parent.width - x - root.shadowRoom
            spacing: Tokens.px(Tokens.space.listItemGap, root.s)

            Repeater {
                id: rows
                model: root.entries

                Item {
                    id: entry
                    required property var modelData
                    required property int index
                    readonly property int item: root.itemOf[index] ?? -1
                    readonly property bool isItem: item >= 0
                    readonly property bool isGroup: !isItem && modelData?.group !== undefined
                    readonly property bool isSearch: modelData?.searchLine === true
                    readonly property bool isEmpty: modelData?.emptyLine !== undefined
                    readonly property bool dim: isItem && modelData?.dim === true
                    readonly property Item row: isItem ? listItem : null

                    // A title's line box is its text size, as the mockup's (CSS line-height 1): the
                    // label's taller natural line is centered on it.
                    readonly property int topPad: isGroup && index > 0 ? root.groupTop : 0
                    width: column.width
                    height: isItem ? listItem.height
                          : isSearch ? searchHeader.height + root.groupBottom
                          : isEmpty ? emptyLabel.height
                          : isGroup ? topPad + caption.size + root.groupBottom : caption.height

                    SearchHeader {
                        id: searchHeader
                        width: parent.width
                        height: entry.isSearch ? implicitHeight : 0
                        visible: entry.isSearch
                        s: root.s
                        query: String(root.search?.query ?? "")
                        count: Number(root.search?.count ?? 0)
                    }

                    // "No apps match.": the mockup's 23 px line, 8 px above and below, 16 px in.
                    Label {
                        id: emptyLabel
                        x: Tokens.px(16, root.s)
                        width: parent.width - x
                        height: entry.isEmpty ? implicitHeight + Tokens.px(16, root.s) : 0
                        topPadding: Tokens.px(8, root.s)
                        visible: entry.isEmpty
                        s: root.s
                        role: "standard"
                        font.weight: Font.Medium
                        font.variableAxes: ({ "wght": Font.Medium })
                        wrapMode: Text.Wrap
                        text: String(entry.modelData?.emptyLine ?? "")
                        color: Tokens.color.mediumGray
                    }

                    Label {
                        id: caption
                        y: entry.topPad - (entry.isGroup ? Math.round((implicitHeight - size) / 2) : 0)
                        width: parent.width
                        visible: !entry.isItem && !entry.isSearch && !entry.isEmpty
                        s: root.s
                        role: "small"
                        wrapMode: Text.Wrap
                        text: String(entry.modelData?.group ?? entry.modelData?.note ?? "")
                        color: Tokens.color.mediumGray
                    }

                    ListItem {
                        id: listItem
                        width: parent.width
                        visible: entry.isItem
                        s: root.s
                        variant: root.variant
                        trailingRole: root.trailingRole
                        text: String(entry.modelData?.label ?? "")
                        trailing: String(entry.modelData?.trailing ?? "")
                        state: entry.item === root.currentIndex ? (root.focused ? "hovered" : "selected")
                             : entry.dim ? "dimmed" : "normal"

                        onHoveredChanged: {
                            if (!hovered || !entry.isItem)
                                return;
                            root.hoveredIndex(entry.item);
                            if (root.keysEnabled)
                                root.currentIndex = entry.item;
                        }
                        onClicked: {
                            if (root.keysEnabled)
                                root.currentIndex = entry.item;
                            root.activated(entry.item);
                        }
                    }

                    // A dimmed item with the cursor: an ink veil leaves its light text at 55%, as
                    // the OptionRow does.
                    Rectangle {
                        width: listItem.inkW
                        height: listItem.bandH
                        visible: entry.dim && width > 0
                        color: Qt.rgba(Tokens.color.darkGray.r, Tokens.color.darkGray.g, Tokens.color.darkGray.b, 0.45)
                    }
                }
            }
        }
    }
}
