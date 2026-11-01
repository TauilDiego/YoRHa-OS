pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../ds/composites"
import "../services"
import "../strings"

// The settings pop-up's body (spec 003): the categories on the left, the category's options in
// the middle and, on the right, a card about what has the focus; the key hints go to the
// pop-up's footer through `keys`. Laid out in game px of the 1612×908 panel frame times `s`
// (contracts/components.md); with `stretch`, the columns' x and widths follow the page's width.
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
    // spec 007 (the pause menu's SYSTEM tab): where the lists start (game px; their captions sit 34
    // above), and hints added to the footer's keys.
    property real startY: 170
    property var extraKeys: []
    // spec 013: the columns come from the page's own width, in the frame's proportions (the
    // full-screen menu), as PickerLayout.stretch does on the other tabs.
    property bool stretch: false

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
    // A horizontal position or width of the 1612 px frame: scaled with `s`, or (stretch) with the width.
    function hx(v: real): int {
        return stretch ? Math.round(v * width / Tokens.space.popupW) : u(v);
    }

    // spec 008 (FR-029, R12): no OSD for a value this page already shows. While the focus is on
    // Sound › Volume or Mute, volume changes show no OSD; on Display › Brightness, brightness ones.
    // Only while the page shows (in the pause menu it stays alive under the other tabs).
    readonly property string focusKey: visible && column === "options" && opt ? catId + "." + opt.id : ""
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

    // --- spec 013, front C: the choice pop-up (FR-025 to FR-027) ----------------------------------------
    // Enter (or a click) on a choice of more than 3 values, or on a "multi" option, opens the pop-up
    // glued to the row; ←→ still change a choice's value in place. choiceId is "cat.opt" while it is
    // open. A single choice stores the picked value and closes; a multi one stores its marks when it
    // closes, however it closes (Esc, a click outside).
    property string choiceId: ""
    property string choiceCat: ""
    property string choiceOptId: ""
    property bool choiceMulti: false
    // { option, values, selected, multi, checked[] } or null (the `pause dump`'s `choice`)
    readonly property var choiceState: choiceId === "" ? null : {
        option: choiceId,
        values: choicePopup.values,
        selected: choicePopup.current,
        multi: choiceMulti,
        checked: choiceMulti ? choicePopup.marked : []
    }

    function activateOption(o: var): void {
        if (SettingsModel.opensPopup(o) && !SettingsModel.isDimmed(catId, o.id))
            openChoice();
        else
            SettingsModel.activate(catId, o.id);
    }

    // "" on success, else why not.
    function openChoice(): string {
        const o = column === "options" ? opt : null;
        const row = o ? options.rowAt(option) : null;
        if (!o || !row)
            return "error: no option has the focus";
        if (!SettingsModel.opensPopup(o) || SettingsModel.isDimmed(catId, o.id))
            return "error: this option has no choice pop-up";
        const v = SettingsModel.value(catId, o.id);
        const p = row.mapToItem(root, 0, 0);
        choiceMulti = o.type === "multi";
        choiceCat = catId;
        choiceOptId = o.id;
        choicePopup.values = o.values;
        choicePopup.multi = choiceMulti;
        choicePopup.marked = choiceMulti ? v : [];
        choicePopup.current = choiceMulti ? (v[0] ?? 0) : v;
        choicePopup.anchorX = p.x + row.width;
        choicePopup.anchorY = p.y;
        choicePopup.anchorH = row.height;
        choicePopup.limitTop = listsY - options.railRoom;
        choicePopup.limitBottom = bottomY;
        choiceId = catId + "." + o.id;
        choicePopup.open = true;
        choicePopup.forceActiveFocus();
        Sounds.play("choiceOpen");               // junction: front C's pop-up, front D's sounds
        return "";
    }

    function closeChoice(): void {
        if (choiceId === "")
            return;
        if (choiceMulti)
            SettingsModel.setMarked(choiceCat, choiceOptId, choicePopup.marked);
        choicePopup.open = false;
        choiceId = "";
        root.forceActiveFocus();
    }

    // Where the pop-up's plate and the cursor's row are on the screen (tests), or null.
    function choiceGeometry(): var {
        return choiceId === "" ? null : choicePopup.geometry();
    }

    // `pause choice`: open | pick <i> | toggle <i> | close; "ok" or "error: …".
    function choiceCommand(cmd: string, arg: string): string {
        if (cmd === "open") {
            const err = openChoice();
            return err === "" ? "ok" : err;
        }
        if (choiceId === "")
            return "error: no choice pop-up is open";
        const i = parseInt(arg);
        if (cmd === "close") {
            closeChoice();
            return "ok";
        }
        if (cmd !== "pick" && cmd !== "toggle")
            return `error: unknown command ${cmd} (open, pick, toggle or close)`;
        if (!Number.isInteger(i) || i < 0 || i >= choicePopup.count)
            return `error: ${arg} is not a value index`;
        if (cmd === "pick" && choiceMulti)
            return "error: a multiple choice marks with toggle";
        if (cmd === "toggle" && !choiceMulti)
            return "error: a single choice picks with pick";
        if (cmd === "pick")
            choicePopup.activate(i);
        else if (!choicePopup.toggle(i))
            return "error: at least one value stays marked";
        return "ok";
    }
    // --- end front C ------------------------------------------------------------------------------------

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
        choicePopup.open = false;           // spec 013: a reopened menu has no pop-up
        choiceId = "";
        column = "categories";
        category = Math.max(0, Math.min(i, Math.max(0, cats.length - 1)));
        option = 0;
    }

    Keys.onPressed: event => {
        const k = event.key;
        const n = opts.length;
        event.accepted = true;
        if (column === "categories") {
            if (k === Qt.Key_Up && cats.length > 0) {
                Sounds.play("move");             // spec 013, front D
                setCategory((category - 1 + cats.length) % cats.length);
            } else if (k === Qt.Key_Down && cats.length > 0) {
                Sounds.play("move");             // spec 013, front D
                setCategory((category + 1) % cats.length);
            } else if (k === Qt.Key_Right || k === Qt.Key_Return || k === Qt.Key_Enter) {
                if (opts.length > 0)
                    Sounds.play("confirm");      // spec 013, front D
                enterOptions();
            }
            else if (k === Qt.Key_Escape)
                closeRequested();
            else
                event.accepted = false;
            return;
        }
        const o = opts[option];
        if (k === Qt.Key_Up) {
            Sounds.play("move");                 // spec 013, front D
            option = (option - 1 + n) % n;
        } else if (k === Qt.Key_Down) {
            Sounds.play("move");                 // spec 013, front D
            option = (option + 1) % n;
        } else if (k === Qt.Key_Left) {
            if (changes(o))
                SettingsModel.step(catId, o.id, -1);
            else {
                Sounds.play("back");             // spec 013, front D
                column = "categories";
            }
        } else if (k === Qt.Key_Right) {
            if (changes(o))
                SettingsModel.step(catId, o.id, 1);
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter)
            activateOption(o);
        else if (k === Qt.Key_Escape) {
            Sounds.play("back");                 // spec 013, front D
            column = "categories";
        } else
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
        if (h.column !== column || (h.column === "categories" ? h.index !== category : h.index !== option))
            Sounds.play("move");                 // spec 013, front D
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
                value: value ? rectOf(value, 0, 0, value.width, value.height) : null,
                // spec 013: the three columns (the middle one is the option rows, past the kite's room)
                columns: {
                    left: rectOf(categoryList, 0, 0, categoryList.width, categoryList.height),
                    middle: rectOf(options, options.selectorRoom, 0, hx(Tokens.space.settingsOptsW), options.height),
                    right: rectOf(card, 0, 0, card.width, card.height)
                }
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
        // spec 013: a "multi" option the compositor can't apply says why
        const multiNote = opt.type === "multi" ? Compositor.keyboardLayoutsNote : "";
        return {
            title: opt.label,
            text: opt.desc ?? "",
            note: dimmed ? SettingsModel.needsText(catId, opt.id) : busy ? String(opt.busy ?? "") : multiNote,
            kind: dimmed || multiNote !== "" ? "alert" : "info",
            meta: opt.type === "multi" ? [{ label: Strings.settings.nowLabel, value: SettingsModel.display(catId, opt.id) }]
                : SettingsModel.hasValue(opt) ? [
                { label: Strings.settings.defaultLabel, value: SettingsModel.defaultDisplay(catId, opt.id) },
                { label: Strings.settings.nowLabel, value: SettingsModel.display(catId, opt.id) }
            ] : []
        };
    }

    // The extra hints go before Esc, as in the pause menu's mockup ("… Tab Next tab, Esc Close").
    readonly property var keys: choiceId !== "" ? choiceKeys : listKeys
    // spec 013: the pop-up takes Tab too, so the hints have no "Next tab"
    readonly property var choiceKeys: [
        { key: Strings.settings.keyUpDown, label: Strings.settings.select },
        { key: Strings.settings.keyEnter, label: choiceMulti ? Strings.settings.mark : Strings.settings.choose },
        { key: Strings.settings.keyEsc, label: choiceMulti ? Strings.settings.done : Strings.settings.cancel }
    ]
    readonly property var listKeys: {
        const b = baseKeys, last = b[b.length - 1];
        return last?.key === Strings.settings.keyEsc ? b.slice(0, -1).concat(extraKeys, [last]) : b.concat(extraKeys);
    }
    readonly property var baseKeys: {
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
        else if (!dimmed && opt.type === "multi")
            out.push({ key: S.keyEnter, label: S.open });
        out.push({ key: S.keyEsc, label: S.back });
        return out;
    }

    // --- layout ----------------------------------------------------------------------------------
    // Lists start at y 170 with their items (the rails go 7 px above); the footer rule sits
    // 88 px above the panel's bottom, and the columns stop 24 px before it.
    readonly property int listsY: u(startY)
    readonly property int optionsX: hx(480)
    readonly property int bottomY: height - u(Tokens.space.popupH - 820) - u(24)

    Label {
        x: categoryList.x + categoryList.itemX
        y: root.u(root.startY - 34)
        s: root.s
        role: "small"
        text: Strings.settings.categories
        color: Tokens.color.mediumGray
    }

    CursorList {
        id: categoryList
        x: root.hx(48)
        y: root.listsY - railRoom
        width: itemX + root.hx(Tokens.space.settingsCatsW)
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
            Sounds.play("confirm");              // spec 013, front D
            root.setCategory(index);
            root.enterOptions();
        }
    }

    // The options column's caption: the category's name and how many settings it has.
    Row {
        x: root.optionsX
        y: root.u(root.startY - 34)
        spacing: root.u(14)
        visible: root.cat !== null

        Label {
            s: root.s
            role: "small"
            upper: true
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": Font.DemiBold })
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.hx(Tokens.space.settingsOptsW) - countLabel.implicitWidth - parent.spacing)
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
        width: root.hx(Tokens.space.settingsOptsW) + selectorRoom + shadowRoom
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
            root.activateOption(root.opts[index]);
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
        x: root.hx(1124)
        y: root.listsY
        width: root.hx(Tokens.space.settingsCardW)
        s: root.s
        minHeight: root.u(360)
        maxHeight: root.bottomY - y
        title: root.cardInfo.title
        text: root.cardInfo.text
        note: root.cardInfo.note
        noteKind: root.cardInfo.kind
        meta: root.cardInfo.meta
    }

    // spec 013, front C: the choice pop-up, over the whole page (and so the menu's panel)
    ChoicePopup {
        id: choicePopup
        anchors.fill: parent
        s: root.s
        onPicked: index => {
            Sounds.play("choicePick");           // junction: front D's sounds on front C's pop-up
            SettingsModel.set(root.choiceCat, root.choiceOptId, index);
            root.closeChoice();
        }
        onToggled: Sounds.play("choicePick")
        onCurrentChanged: if (open) Sounds.play("move")
        onDismissed: {
            Sounds.play("back");
            root.closeChoice();
        }
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
