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
//                                spec 008: also `lead`, `tag` and `markColor` (ListItem), for the
//                                text log's rows (who speaks, NEW, the critical square).
// `currentIndex` counts items only. As in the CursorList (spec 003): `focused: false` draws the
// current item "selected" (its kite light and still); `wrap` makes move() go round; with
// `keysEnabled: false` the parent drives it: no keys, and hover and clicks only report
// (hoveredIndex, activated) without moving `currentIndex`.
// The parent sets the size. Taller content scrolls at once, by whole entries, so the current item
// with its rails (and its group's title, when it is the group's first) is always in view.
Item {
    id: root

    property real s: 1
    property var model: []
    property int currentIndex: 0
    property string variant: "opaque"
    property bool focused: true
    property bool wrap: true
    property bool keysEnabled: true

    signal activated(int index)
    signal hoveredIndex(int index)

    readonly property var entries: Array.isArray(model) ? model : []
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
        return e !== null && typeof e === "object" && e.group === undefined && e.note === undefined;
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
    function follow(): void {
        const e = entryOf[currentIndex];
        const row = rows.itemAt(e ?? -1);
        if (!row || height <= 0) {
            scrollY = 0;
            return;
        }
        // From the group's title (titles and notes right above the item) to the bottom rail.
        let first = e;
        while (first > 0 && itemOf[first - 1] < 0)
            first--;
        const above = rows.itemAt(first);
        const a = topRoom + (first < e && above ? above.y : row.y - railRoom);
        const b = topRoom + row.y + row.height + railRoom;
        let y = scrollY;
        if (a < y)
            y = a;
        else if (b > y + height)
            y = b - height;
        scrollY = Math.max(0, Math.min(y, contentHeight - height));
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
        height: root.height
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
                    readonly property bool dim: isItem && modelData?.dim === true
                    readonly property Item row: isItem ? listItem : null

                    // A title's line box is its text size, as the mockup's (CSS line-height 1): the
                    // label's taller natural line is centered on it.
                    readonly property int topPad: isGroup && index > 0 ? root.groupTop : 0
                    width: column.width
                    height: isItem ? listItem.height
                          : isGroup ? topPad + caption.size + root.groupBottom : caption.height

                    Label {
                        id: caption
                        y: entry.topPad - (entry.isGroup ? Math.round((implicitHeight - size) / 2) : 0)
                        width: parent.width
                        visible: !entry.isItem
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
                        trailingRole: "small"
                        text: String(entry.modelData?.label ?? "")
                        trailing: String(entry.modelData?.trailing ?? "")
                        lead: String(entry.modelData?.lead ?? "")
                        tag: String(entry.modelData?.tag ?? "")
                        markColor: entry.modelData?.markColor ?? "transparent"
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
