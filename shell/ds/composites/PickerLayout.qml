pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"
import "../../strings"

// List + preview + options (spec 004, design-system §8): the game's ITEMS screen as a picker's
// body inside a PopupFrame. Laid out in game px of the 1612×908 panel frame times `s`, from y 150:
//   left    a GroupedList of `entries`, the cursor on item `index`;
//   middle  the preview: what the default property holds (e.g. the wallpaper PreviewCard), at
//           x 560, Tokens.space.pickerPreviewW wide;
//   right   the Options card at x 1160: one OptionRow per option (choices, ◂ value ▸, drawn at
//           Tokens.space.pickerOptionScale to fit), a light rule, then label/value info rows.
// One focus, in one of two columns (design-system §7, "Foco em duas colunas"):
//   list     ↑↓ move (wrapping; titles are skipped); Enter applies the item (not a dimmed one);
//            → goes to the first option; Esc closes.
//   options  ↑↓ move (wrapping); ←→ change the value, without wrapping; ← on the first value goes
//            back to the list; Enter advances the value (wrapping); Esc goes back.
// The mouse moves the focus too, but only when the pointer really moved (as in the settings). A
// click on an item applies it; on a row's arrow, steps the value; anywhere else on a row, advances
// it. `keys` are the hints of the focus, for the pop-up's footer.
//   options: [{ id, label, values: [text] }]; values: option id → index of its current value;
//   info: [{ label, value }].
// spec 007 (the pause menu's APPS and WINDOWS): `startY` (game px, 150 by default) is where the columns
// start; `searchHeader` ({ query, count } or null) and `emptyText` go to the GroupedList; an option
// can have a `type`:
//   choice  (default) as above;
//   toggle  ◂ ON ▸ / ◂ OFF ▸ (its value 0/1): ← → and Enter flip it;
//   action  label + arrow (`text`): Enter or a click emits triggered(option); → does nothing and ←
//           goes back to the list.
// Keys it doesn't use (Tab, letters, Backspace) stay unaccepted, for the page around it.
// `optionsVisible` (default true; T043) hides the Options card, e.g. APPS with a search that found
// nothing. The wheel over a list taller than its column scrolls it by whole entries; a cursor left
// out of view comes back into it, and the focus goes to the list (as with the pointer).
FocusScope {
    id: root

    property real s: 1
    property var entries: []
    property int index: 0
    property string column: "list"              // "list" | "options"
    property int option: 0
    property var options: []
    property var values: ({})
    property var info: []
    property string optionsTitle: Strings.wallpaper.options
    property string applyLabel: Strings.wallpaper.keyApply
    default property alias preview: previewSlot.data
    // spec 007
    property real startY: 150
    property var searchHeader: null
    property string emptyText: ""
    property string trailingRole: "small"
    property bool optionsVisible: true
    readonly property GroupedList groupedList: list

    signal applied(int index)
    signal picked(int option, int value)
    signal closeRequested()
    signal triggered(int option)

    readonly property int count: list.count
    readonly property bool currentDim: list.itemData(index)?.dim === true
    readonly property var opt: column === "options" ? (options[option] ?? null) : null
    readonly property int previewWidth: previewSlot.width

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    function valueOf(i: int): int {
        return Number(values[options[i]?.id] ?? 0);
    }

    function lengthOf(i: int): int {
        return typeOf(i) === "toggle" ? 2 : (options[i]?.values?.length ?? 0);
    }

    function typeOf(i: int): string {
        return String(options[i]?.type ?? "choice");
    }

    function enterOptions(): void {
        if (options.length === 0)
            return;
        column = "options";
        option = 0;
    }

    // Back to the list, on item `i` (a reopened picker).
    function restart(i: int): void {
        column = "list";
        index = Math.max(0, Math.min(i, Math.max(0, count - 1)));
        option = 0;
    }

    function apply(i: int): void {
        if (list.itemData(i)?.dim !== true)
            applied(i);
    }

    // A value changed by ← → or an arrow: no wrapping; `back` (keys only) leaves on ← at the start.
    function step(i: int, dir: int, back: bool): void {
        const t = typeOf(i);
        if (t === "action") {
            if (dir < 0 && back)
                column = "list";
            return;
        }
        if (t === "toggle") {
            picked(i, valueOf(i) ? 0 : 1);
            return;
        }
        const v = valueOf(i), n = lengthOf(i);
        if (dir < 0 && v <= 0) {
            if (back)
                column = "list";
            return;
        }
        if (dir > 0 && v >= n - 1)
            return;
        picked(i, v + dir);
    }

    // Enter or a click on a row: the next value, wrapping.
    function advance(i: int): void {
        if (typeOf(i) === "action") {
            triggered(i);
            return;
        }
        const n = lengthOf(i);
        if (n > 0)
            picked(i, (valueOf(i) + 1) % n);
    }

    // The options may shrink (e.g. a row only pictures have): keep the cursor on one.
    onOptionsChanged: {
        if (option >= options.length)
            option = Math.max(0, options.length - 1);
        if (options.length === 0 && column === "options")
            column = "list";
    }

    Keys.onPressed: event => {
        const k = event.key;
        event.accepted = true;
        if (column === "list") {
            if (k === Qt.Key_Up && count > 0)
                index = (index - 1 + count) % count;
            else if (k === Qt.Key_Down && count > 0)
                index = (index + 1) % count;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                apply(index);
            else if (k === Qt.Key_Right)
                enterOptions();
            else if (k === Qt.Key_Escape)
                closeRequested();
            else if (k !== Qt.Key_Left)
                event.accepted = false;
            return;
        }
        const n = options.length;
        if (k === Qt.Key_Up && n > 0)
            option = (option - 1 + n) % n;
        else if (k === Qt.Key_Down && n > 0)
            option = (option + 1) % n;
        else if (k === Qt.Key_Left)
            step(option, -1, true);
        else if (k === Qt.Key_Right)
            step(option, 1, true);
        else if (k === Qt.Key_Return || k === Qt.Key_Enter)
            advance(option);
        else if (k === Qt.Key_Escape)
            column = "list";
        else
            event.accepted = false;
    }

    // --- mouse (as the settings page): hover moves the focus only when the pointer really moved;
    // a hover is noted and settled after the event, once the pointer handler has said so.
    property var pendingHover: null              // { column, index }
    property bool pointerMoved: false

    function noteHover(col: string, i: int): void {
        pendingHover = { column: col, index: i };
        Qt.callLater(root.settleHover);
    }

    function settleHover(): void {
        const h = pendingHover;
        const moved = pointerMoved;
        pendingHover = null;
        pointerMoved = false;
        if (!h || !moved)
            return;
        column = h.column;
        if (h.column === "list")
            index = h.index;
        else
            option = h.index;
    }

    // --- what the footer says --------------------------------------------------------------------
    readonly property var keys: {
        const W = Strings.wallpaper, K = Strings.settings;
        if (column === "options") {
            const o = options[option];
            const mid = o?.type === "action" ? { key: K.keyEnter, label: String(o.text ?? "") } : { key: K.keyLeftRight, label: W.keyChange };
            return [{ key: K.keyUpDown, label: W.keySelect }, mid, { key: K.keyEsc, label: W.keyBack }];
        }
        const out = [{ key: K.keyUpDown, label: W.keySelect }];
        if (count > 0 && !currentDim)
            out.push({ key: K.keyEnter, label: applyLabel });
        if (options.length > 0)
            out.push({ key: K.keyRight, label: W.keyOptions });
        out.push({ key: K.keyEsc, label: W.keyClose });
        return out;
    }

    // --- geometry, for a dump (the item or option in focus, its value) ----------------------------
    function rectOf(item: Item, x: real, y: real, w: real, h: real): var {
        if (!item)
            return null;
        const p = item.mapToItem(null, x, y);
        return { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(w), h: Math.round(h) };
    }

    // Option row `i` (an OptionRow, typed var so its own properties can be read).
    function rowAt(i: int): var {
        return optionRows.itemAt(i);
    }

    function geometry(): var {
        const row = column === "options" ? rowAt(option) : list.itemAt(index);
        const value = column === "options" ? (rowAt(option)?.valueItem ?? null) : null;
        return {
            s: Math.round(s * 1000) / 1000,
            panel: rectOf(root, 0, 0, width, height),
            item: row ? rectOf(row, 0, 0, row.width, row.height) : null,
            value: value ? rectOf(value, 0, 0, value.width, value.height) : null,
            preview: rectOf(previewSlot, 0, 0, previewSlot.width, previewSlot.childrenRect.height),
            options: optionsVisible ? rectOf(optionsBox, 0, 0, optionsBox.width, optionsBox.height) : null
        };
    }

    // --- layout ----------------------------------------------------------------------------------
    // The columns start at y 150 and stop 24 px above the footer rule (88 px above the bottom).
    readonly property int topY: u(startY)
    readonly property int bottomY: height - u(Tokens.space.popupH - 820) - u(24)

    GroupedList {
        id: list
        x: root.u(48)
        y: root.topY
        width: implicitWidth
        height: Math.min(implicitHeight, root.bottomY - y)
        s: root.s
        model: root.entries
        currentIndex: root.index
        focused: root.column === "list"
        keysEnabled: false
        search: root.searchHeader
        emptyText: root.emptyText
        trailingRole: root.trailingRole
        onHoveredIndex: i => root.noteHover("list", i)
        onCursorRequested: i => {
            root.column = "list";
            root.index = i;
        }
        onActivated: i => {
            root.column = "list";
            root.index = i;
            root.apply(i);
        }
    }

    Item {
        id: previewSlot
        x: root.u(560)
        y: root.topY
        width: root.u(Tokens.space.pickerPreviewW)
        height: root.bottomY - y
    }

    // The Options card: the rows hang their kite into the 40 px gap on the card's left.
    Item {
        id: optionsBox
        x: root.u(1160)
        y: root.topY
        width: root.u(Tokens.space.pickerOptionsW)
        height: infoColumn.y + infoColumn.height + root.u(22)
        visible: root.optionsVisible

        readonly property int railRoom: Tokens.px(Tokens.space.railGap, root.s) + Tokens.line(Tokens.space.rail, root.s)

        Card {
            id: optionsCard
            anchors.fill: parent
            s: root.s
            mark: true
            title: root.optionsTitle
        }

        Column {
            id: rowColumn
            y: optionsCard.headerH + root.u(18)
            width: parent.width
            spacing: Tokens.px(Tokens.space.listItemGap, root.s)

            Repeater {
                id: optionRows
                model: root.options

                OptionRow {
                    required property var modelData
                    required property int index

                    width: rowColumn.width
                    s: root.s
                    contentScale: Tokens.space.pickerOptionScale
                    option: Object.assign({ type: "choice" }, modelData)
                    value: modelData?.type === "toggle" ? root.valueOf(index) !== 0 : root.valueOf(index)
                    focused: root.column === "options" && index === root.option

                    onHoveredChanged: if (hovered) root.noteHover("options", index)
                    onStepped: dir => {
                        root.column = "options";
                        root.option = index;
                        root.step(index, dir, false);
                    }
                    onActivated: {
                        root.column = "options";
                        root.option = index;
                        root.advance(index);
                    }
                }
            }
        }

        Rectangle {
            id: infoRule
            y: rowColumn.y + rowColumn.height + optionsBox.railRoom + root.u(6)
            width: parent.width
            height: Tokens.line(Tokens.space.rule, root.s)
            visible: root.info.length > 0
            color: Tokens.color.lightGray
        }

        // The labels' column is as wide as the widest label; values are right-aligned and wrap.
        Column {
            id: labelMeasure
            visible: false
            Repeater {
                model: root.info
                Label {
                    required property var modelData
                    s: root.s
                    role: "small"
                    upper: true
                    text: String(modelData?.label ?? "")
                }
            }
        }

        Column {
            id: infoColumn
            x: optionsCard.margin
            y: root.info.length > 0 ? infoRule.y + infoRule.height + root.u(14) : rowColumn.y + rowColumn.height
            width: parent.width - 2 * x
            spacing: root.u(12)

            Repeater {
                model: root.info

                Item {
                    id: infoRow
                    required property var modelData
                    width: infoColumn.width
                    height: Math.max(infoLabel.implicitHeight, infoValue.implicitHeight)

                    Label {
                        id: infoLabel
                        s: root.s
                        role: "small"
                        upper: true
                        text: String(infoRow.modelData?.label ?? "")
                        color: Tokens.color.mediumGray
                    }
                    Label {
                        id: infoValue
                        x: Math.ceil(labelMeasure.implicitWidth) + root.u(18)
                        width: parent.width - x
                        s: root.s
                        role: "small"
                        font.weight: Font.DemiBold
                        font.variableAxes: ({ "wght": Font.DemiBold })
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.Wrap
                        text: String(infoRow.modelData?.value ?? "")
                    }
                }
            }
        }
    }

    // The pointer's moves, seen by the layout itself (an item on top would take the rows' hover).
    HoverHandler {
        id: pointer
        property point last: Qt.point(NaN, NaN)
        onPointChanged: {
            const p = point.scenePosition;
            if (p.x === last.x && p.y === last.y)
                return;
            const first = isNaN(last.x);
            last = p;
            if (first)
                return;
            root.pointerMoved = true;
            Qt.callLater(root.settleHover);
        }
    }
}
