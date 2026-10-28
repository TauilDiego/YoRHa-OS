pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../ds/composites"
import "../services"
import "../strings"

// The settings pop-up's body (spec 003): the categories on the left, the category's options in
// the middle and, on the right, a card about what has the focus; the key hints go to the
// pop-up's footer through `keys`. Laid out in game px of the 1612×908 panel frame times `s`
// (contracts/components.md).
// One focus, in one of two columns (FR-010, research R8):
//   categories  ↑↓ move (wrapping) and show that category's options at once; → or Enter go to
//               the first option; Esc closes.
//   options     ↑↓ move (wrapping); ←→ change a value that changes; ← on a row that doesn't
//               (action, info, dimmed) goes back; Enter toggles / advances / runs; Esc goes back.
// The mouse moves the focus too (FR-011): hovering an item focuses it (a category also shows its
// options), a click on a category enters its options, a click on an option is its Enter.
FocusScope {
    id: root

    property real s: 1
    property int category: 0
    property string column: "categories"        // "categories" | "options"
    property int option: 0

    signal closeRequested()

    readonly property var cats: SettingsModel.categories
    readonly property var cat: cats.length > 0 ? cats[Math.max(0, Math.min(category, cats.length - 1))] : null
    readonly property string catId: cat?.id ?? ""
    // spec 008: live notifications options take their texts and values from NotifyPrefs (resolve).
    readonly property var opts: (cat?.options ?? []).map(o => SettingsModel.resolve(o))
    readonly property var opt: column === "options" ? (opts[option] ?? null) : null

    // The option list's maps; they re-evaluate when any value changes (SettingsModel.current).
    readonly property var values: {
        const m = {};
        for (const o of opts)
            m[o.id] = SettingsModel.value(catId, o.id);
        return m;
    }
    readonly property var dims: {
        const m = {};
        for (const o of opts)
            m[o.id] = SettingsModel.isDimmed(catId, o.id);
        return m;
    }

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    // spec 008 (FR-029, R12): no OSD for a value this page already shows. While the focus is on
    // Sound › Volume or Mute, volume changes show no OSD; on Display › Brightness, brightness ones.
    readonly property string focusKey: column === "options" && opt ? catId + "." + opt.id : ""
    function syncOsd(): void {
        Osd.suppress("volume", focusKey === "sound.volume" || focusKey === "sound.mute");
        Osd.suppress("brightness", focusKey === "display.brightness");
    }
    onFocusKeyChanged: syncOsd()
    Component.onDestruction: {
        Osd.suppress("volume", false);
        Osd.suppress("brightness", false);
    }

    // A row whose value ← and → change (toggle, choice, slider, not dimmed).
    function changes(o: var): bool {
        return SettingsModel.hasValue(o) && !SettingsModel.isDimmed(catId, o.id);
    }

    function setCategory(i: int): void {
        if (i === category)
            return;
        category = i;
        option = 0;
    }

    function enterOptions(): void {
        if (opts.length === 0)
            return;
        column = "options";
        option = 0;
    }

    // Back to the categories, on category `i` (a reopened pop-up, `settings reset`).
    function restart(i: int): void {
        column = "categories";
        category = Math.max(0, Math.min(i, Math.max(0, cats.length - 1)));
        option = 0;
    }

    Keys.onPressed: event => {
        const k = event.key;
        const n = opts.length;
        event.accepted = true;
        if (column === "categories") {
            if (k === Qt.Key_Up && cats.length > 0)
                setCategory((category - 1 + cats.length) % cats.length);
            else if (k === Qt.Key_Down && cats.length > 0)
                setCategory((category + 1) % cats.length);
            else if (k === Qt.Key_Right || k === Qt.Key_Return || k === Qt.Key_Enter)
                enterOptions();
            else if (k === Qt.Key_Escape)
                closeRequested();
            else
                event.accepted = false;
            return;
        }
        const o = opts[option];
        if (k === Qt.Key_Up)
            option = (option - 1 + n) % n;
        else if (k === Qt.Key_Down)
            option = (option + 1) % n;
        else if (k === Qt.Key_Left) {
            if (changes(o))
                SettingsModel.step(catId, o.id, -1);
            else
                column = "categories";
        } else if (k === Qt.Key_Right) {
            if (changes(o))
                SettingsModel.step(catId, o.id, 1);
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter)
            SettingsModel.activate(catId, o.id);
        else if (k === Qt.Key_Escape)
            column = "categories";
        else
            event.accepted = false;
    }

    // --- mouse -------------------------------------------------------------------------------------
    // Hover moves the focus only when the pointer really moved. Qt re-sends hover to items that
    // appear or move under a resting pointer (the pop-up opening under it, a new category's rows
    // after ↑↓), and that must not take the focus from the keyboard. A hover is noted and
    // settled after the event, once the pointer handler (on top) has said whether it moved.
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
        if (h.column === "categories") {
            column = "categories";
            setCategory(h.index);
        } else {
            column = "options";
            option = h.index;
        }
    }

    // --- dump (contracts/ipc.md) -----------------------------------------------------------------
    function rectOf(item: Item, x: real, y: real, w: real, h: real): var {
        if (!item)
            return null;
        const p = item.mapToItem(null, x, y);
        return { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(w), h: Math.round(h) };
    }

    function dumpState(): var {
        const row = column === "options" ? options.rowAt(option) : null;
        const value = row?.valueItem ?? null;
        const catItemY = categoryList.railRoom + category * options.pitch;
        return {
            focus: column,
            category: catId,
            option: opt ? opt.id : null,
            keys: keys.map(k => `${k.key} ${k.label}`),
            card: { title: card.title, note: card.note },
            geometry: {
                s: Math.round(s * 1000) / 1000,
                panel: rectOf(root, 0, 0, width, height),
                item: row ? rectOf(row, 0, 0, row.width, row.height)
                          : cat ? rectOf(categoryList, categoryList.itemX, catItemY, categoryList.width - categoryList.itemX, options.rowH) : null,
                value: value ? rectOf(value, 0, 0, value.width, value.height) : null
            }
        };
    }

    // --- what the card and the footer say (FR-014, FR-015) ------------------------------------
    readonly property var cardInfo: {
        if (SettingsModel.error !== "")
            return { title: Strings.settings.title, text: "", note: SettingsModel.error, kind: "alert", meta: [] };
        if (!cat)
            return { title: "", text: "", note: "", kind: "alert", meta: [] };
        if (!opt)
            return {
                title: cat.label,
                text: cat.about ?? "",
                note: "",
                kind: "alert",
                meta: [{ label: Strings.settings.count, value: String(opts.length) }]
            };
        const dimmed = SettingsModel.isDimmed(catId, opt.id);
        const busy = SettingsModel.busy === catId + "." + opt.id;
        return {
            title: opt.label,
            text: opt.desc ?? "",
            note: dimmed ? SettingsModel.needsText(catId, opt.id) : busy ? String(opt.busy ?? "") : "",
            kind: dimmed ? "alert" : "info",
            meta: SettingsModel.hasValue(opt) ? [
                { label: Strings.settings.defaultLabel, value: SettingsModel.defaultDisplay(catId, opt.id) },
                { label: Strings.settings.nowLabel, value: SettingsModel.display(catId, opt.id) }
            ] : []
        };
    }

    readonly property var keys: {
        const S = Strings.settings;
        if (!cat)
            return [{ key: S.keyEsc, label: S.close }];
        if (!opt)
            return opts.length > 0
                ? [{ key: S.keyUpDown, label: S.select }, { key: S.keyRight, label: S.open }, { key: S.keyEsc, label: S.close }]
                : [{ key: S.keyUpDown, label: S.select }, { key: S.keyEsc, label: S.close }];
        const out = [{ key: S.keyUpDown, label: S.select }];
        const dimmed = SettingsModel.isDimmed(catId, opt.id);
        if (!dimmed && SettingsModel.hasValue(opt))
            out.push({ key: S.keyLeftRight, label: S.change });
        else if (!dimmed && opt.type === "action")
            out.push({ key: S.keyEnter, label: String(opt.text ?? "") });
        out.push({ key: S.keyEsc, label: S.back });
        return out;
    }

    // --- layout ----------------------------------------------------------------------------------
    // Lists start at y 170 with their items (the rails go 7 px above); the footer rule sits
    // 88 px above the panel's bottom, and the columns stop 24 px before it.
    readonly property int listsY: u(170)
    readonly property int optionsX: u(480)
    readonly property int bottomY: height - u(Tokens.space.popupH - 820) - u(24)

    Label {
        x: categoryList.x + categoryList.itemX
        y: root.u(136)
        s: root.s
        role: "small"
        text: Strings.settings.categories
        color: Tokens.color.mediumGray
    }

    CursorList {
        id: categoryList
        x: root.u(48)
        y: root.listsY - railRoom
        width: itemX + root.u(Tokens.space.settingsCatsW)
        visible: root.cats.length > 0
        s: root.s
        variant: "opaque"
        model: root.cats.map(c => c.label)
        currentIndex: root.category
        focused: root.column === "categories"
        wrap: true
        keysEnabled: false
        onHoveredIndex: index => root.noteHover("categories", index)
        onActivated: index => {
            root.setCategory(index);
            root.enterOptions();
        }
    }

    // The options column's caption: the category's name and how many settings it has.
    Row {
        x: root.optionsX
        y: root.u(136)
        spacing: root.u(14)
        visible: root.cat !== null

        Label {
            s: root.s
            role: "small"
            upper: true
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": Font.DemiBold })
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.u(Tokens.space.settingsOptsW) - countLabel.implicitWidth - parent.spacing)
            text: root.cat?.label ?? ""
        }
        Label {
            id: countLabel
            s: root.s
            role: "small"
            text: `${root.opts.length} ${Strings.settings.count}`
            color: Tokens.color.mediumGray
        }
    }

    OptionList {
        id: options
        x: root.optionsX - selectorRoom
        y: root.listsY - railRoom
        width: root.u(Tokens.space.settingsOptsW) + selectorRoom + shadowRoom
        height: fitHeight(root.bottomY - y)
        s: root.s
        options: root.opts
        values: root.values
        dims: root.dims
        currentIndex: root.option
        focused: root.column === "options"
        onHoveredIndex: index => root.noteHover("options", index)
        onActivated: index => {
            root.column = "options";
            root.option = index;
            SettingsModel.activate(root.catId, root.opts[index].id);
        }
        onStepped: (index, dir) => {
            root.column = "options";
            root.option = index;
            SettingsModel.step(root.catId, root.opts[index].id, dir);
        }
        onPicked: (index, value) => {
            root.column = "options";
            root.option = index;
            SettingsModel.pick(root.catId, root.opts[index].id, value);
        }
    }

    DescriptionCard {
        id: card
        x: root.u(1124)
        y: root.listsY
        width: root.u(Tokens.space.settingsCardW)
        s: root.s
        minHeight: root.u(360)
        maxHeight: root.bottomY - y
        title: root.cardInfo.title
        text: root.cardInfo.text
        note: root.cardInfo.note
        noteKind: root.cardInfo.kind
        meta: root.cardInfo.meta
    }

    // The pointer's moves, seen by the page itself (an item on top would take the rows' hover).
    // Passive: the rows still get their hover; settleHover runs after both have seen the event.
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
