pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../ds/composites"
import "../services"
import "../strings"

// The pause menu's WINDOWS, the open windows (spec 007 US3, FR-015–FR-018), in the PickerLayout:
//   list     the windows grouped by workspace (WORKSPACE 01… in number order, SPECIAL last; inside a
//            group top to bottom, then left to right), each with its title (or the app's name) and
//            the app on the right, the focused one marked ●;
//   preview  a Card with the WorkspaceMap of the chosen window's workspace (it in ink), the whole
//            title under it and "Tiled · W × H" in the footer;
//   options  Focus (action), Workspace ◂ 01 ▸ (moves it at once, without following), Floating
//            ◂ OFF ▸ and Close (action), as the compositor's capabilities allow; then APP, MONITOR,
//            SIZE.
// Enter on the list (or Focus) closes the menu and goes to the window. The cursor follows the
// window's id while the list changes (live: Compositor reads the compositor on its events); when
// the window goes away, the cursor goes to its neighbour (the one below, or above at the end) and,
// if its options were open, the focus goes back to the list. Opens on the focused window (FR-006).
// With no window: "No open windows.", the map of the current workspace, and only Tab and Esc.
FocusScope {
    id: root

    property real s: 1
    property real startY: Tokens.space.pauseBodyY

    signal closeRequested()

    readonly property var ps: Strings.pause
    readonly property var caps: Compositor.capabilities
    readonly property string error: Compositor.windowsError !== "" ? ps.windowsError : ""

    // --- the list --------------------------------------------------------------------------------
    function isSpecial(w: var): bool {
        return Number(w.workspace) < 0 || String(w.workspaceName ?? "").startsWith("special");
    }
    function appName(w: var): string {
        return Apps.byClass(w.appClass)?.name ?? String(w.appClass ?? "");
    }
    // The app on a row's right: the ListItem doesn't cut its trailing text, so a long name is
    // shortened here (the whole name is in APP).
    readonly property int trailingMax: 16
    function shortName(name: string): string {
        return name.length > trailingMax ? name.slice(0, trailingMax - 1).replace(/\s+$/, "") + "…" : name;
    }
    function pad(n: int): string {
        return n < 10 ? `0${n}` : String(n);
    }
    function groupLabel(w: var): string {
        return isSpecial(w) ? ps.special : ps.workspaceN.arg(pad(Number(w.workspace)));
    }

    // [{ label, key, windows: [Window] }] in the list's order.
    readonly property var groups: {
        const by = {};
        for (const w of Compositor.windows) {
            const key = isSpecial(w) ? "special" : String(w.workspace);
            by[key] = by[key] ?? { label: groupLabel(w), key: key, order: isSpecial(w) ? 1e6 : Number(w.workspace), windows: [] };
            by[key].windows.push(w);
        }
        const out = Object.values(by).sort((a, b) => a.order - b.order);
        for (const g of out)
            g.windows.sort((a, b) => (g.key === "special" ? String(a.workspaceName).localeCompare(String(b.workspaceName)) : 0)
                || (a.y - b.y) || (a.x - b.x));
        return out;
    }
    readonly property var flat: groups.reduce((out, g) => out.concat(g.windows), [])
    readonly property var entries: {
        const out = [];
        for (const g of groups) {
            out.push({ group: g.label });
            for (const w of g.windows) {
                const app = appName(w);
                out.push({
                    id: w.id,
                    label: w.title !== "" ? w.title : app,
                    trailing: (w.focused ? ps.focusedMark + " " : "") + shortName(app)
                });
            }
        }
        return out;
    }

    // The cursor follows a window id; `lastIndex` is where it was, for the neighbour.
    property string currentId: ""
    property int lastIndex: 0
    readonly property int index: flat.findIndex(w => w.id === currentId)
    readonly property var item: flat[index] ?? null

    onFlatChanged: follow()

    function follow(): void {
        const i = flat.findIndex(w => w.id === currentId);
        if (i >= 0) {
            lastIndex = i;
            layout.index = i;
            return;
        }
        if (flat.length === 0) {
            currentId = "";
            lastIndex = 0;
            layout.column = "list";
            layout.index = 0;
            return;
        }
        // Gone (or never set): its neighbour, and back to the list if its options were open.
        const n = Math.min(lastIndex, flat.length - 1);
        if (currentId !== "" && layout.column === "options")
            layout.column = "list";
        currentId = flat[n].id;
        lastIndex = n;
        layout.index = n;
    }

    // --- the chosen window's preview, options and info --------------------------------------------
    readonly property var monitorOfItem: {
        const list = Compositor.monitorList;
        const name = item ? item.monitor : Compositor.focusedMonitor;
        return list.find(m => m.name === name) ?? list.find(m => m.focused) ?? list[0] ?? null;
    }
    // With no window: the workspace shown on the monitor.
    readonly property int currentWorkspace: {
        const name = monitorOfItem?.name ?? Compositor.focusedMonitor;
        return Compositor.workspacesFor(name).find(w => w.focused)?.id ?? 1;
    }
    readonly property var mapWindows: item ? Compositor.windows.filter(w => w.workspaceKey === item.workspaceKey) : []
    readonly property string cardTitle: {
        if (!item) {
            const mon = monitorOfItem?.name || Compositor.focusedMonitor;
            const label = ps.workspaceN.arg(pad(currentWorkspace));
            return mon ? ps.windowFoot.arg(label).arg(mon) : label;
        }
        if (isSpecial(item))
            return ps.windowFoot.arg(ps.special).arg(String(item.workspaceName).replace(/^special:?/, "") || item.monitor);
        return ps.windowFoot.arg(groupLabel(item)).arg(item.monitor);
    }
    readonly property string sizeText: item ? ps.sizeValue.arg(item.w).arg(item.h) : ""
    readonly property string cardFoot: item ? ps.windowFoot.arg(item.floating ? ps.floatingState : ps.tiled).arg(sizeText) : ""
    readonly property string cardText: error !== "" ? error : item ? (item.title !== "" ? item.title : appName(item)) : ps.noWindowsText

    // Workspace values: 01–10; a window on a special workspace starts on SPECIAL, before them.
    readonly property bool onSpecial: item !== null && isSpecial(item)
    readonly property var workspaceValues: {
        const v = [];
        if (onSpecial)
            v.push(ps.special);
        for (let n = 1; n <= 10; n++)
            v.push(pad(n));
        return v;
    }
    readonly property var options: {
        if (!item)
            return [];
        const out = [{ id: "focus", label: ps.focus, type: "action", text: ps.go }];
        if (caps.canMoveToWorkspace)
            out.push({ id: "workspace", label: ps.workspace, type: "choice", values: workspaceValues });
        if (caps.canFloat)
            out.push({ id: "floating", label: ps.floating, type: "toggle" });
        out.push({ id: "close", label: ps.close, type: "action", text: ps.close });
        return out;
    }
    readonly property var values: item ? ({
        workspace: onSpecial ? 0 : Math.max(0, Math.min(9, Number(item.workspace) - 1)),
        floating: item.floating ? 1 : 0
    }) : ({})
    readonly property var info: {
        if (!item)
            return [];
        return [
            { label: ps.app, value: appName(item) },
            { label: ps.monitor, value: item.monitor },
            { label: ps.size, value: sizeText }
        ];
    }

    // --- actions -----------------------------------------------------------------------------------
    function focusItem(): void {
        if (!item)
            return;
        const id = item.id;
        closeRequested();
        Compositor.focusWindow(id);
    }

    function pick(o: int, v: int): void {
        const opt = options[o];
        if (!item || !opt)
            return;
        if (opt.id === "workspace") {
            const target = onSpecial ? v : v + 1;
            if (target >= 1 && target !== Number(item.workspace))
                Compositor.moveWindow(item.id, target);
        } else if (opt.id === "floating") {
            if ((v !== 0) !== item.floating)
                Compositor.toggleFloating(item.id);
        }
    }

    function trigger(o: int): void {
        const opt = options[o];
        if (!item || !opt)
            return;
        if (opt.id === "focus")
            focusItem();
        else if (opt.id === "close")
            Compositor.closeWindow(item.id);
    }

    // --- the page's contract (PauseMenu) ----------------------------------------------------------
    readonly property var keys: {
        const K = Strings.settings, W = Strings.wallpaper;
        if (layout.column === "options")
            return layout.keys;
        if (flat.length === 0)
            return [{ key: K.keyEsc, label: W.keyClose }];
        return [{ key: K.keyUpDown, label: W.keySelect }, { key: K.keyEnter, label: ps.focus },
                { key: K.keyRight, label: ps.actions }, { key: K.keyEsc, label: W.keyClose }];
    }
    readonly property string footerLeft: ps.windowsFooter.arg(flat.length).arg(groups.length)

    // The opening state: the list, on the focused window (or the first).
    function restart(): void {
        const f = Compositor.windows.find(w => w.focused);
        currentId = f ? f.id : (flat[0]?.id ?? "");
        lastIndex = 0;
        follow();
        layout.restart(Math.max(0, index));
    }
    function enter(): void {
    }
    function leave(): void {
    }
    function geometry(): var {
        return layout.geometry();
    }
    function dumpState(): var {
        return {
            column: layout.column,
            item: item ? item.id : null,
            groups: groups.map(g => ({ label: g.label, windows: g.windows.map(w => w.id) })),
            map: {
                monitor: monitorOfItem?.name || Compositor.focusedMonitor,
                workspace: item ? Number(item.workspace) : currentWorkspace,
                selected: item ? item.id : null,
                rects: item ? mapWindows.length : 0
            },
            option: layout.column === "options" ? (options[layout.option]?.id ?? null) : null,
            preview: { title: cardTitle, text: cardText, foot: cardFoot },
            info: info.map(i => `${i.label}: ${i.value}`),
            scroll: layout.groupedList.scrollState(),
            error: error
        };
    }

    Component.onCompleted: restart()

    PickerLayout {
        id: layout
        anchors.fill: parent
        s: root.s
        focus: true
        startY: root.startY
        entries: root.entries
        emptyText: root.ps.noWindows
        options: root.options
        values: root.values
        info: root.info
        optionsTitle: root.ps.windowActions
        onIndexChanged: {
            const w = root.flat[layout.index];
            if (w) {
                root.currentId = w.id;
                root.lastIndex = layout.index;
            }
        }
        onApplied: root.focusItem()
        onPicked: (o, v) => root.pick(o, v)
        onTriggered: o => root.trigger(o)
        onCloseRequested: root.closeRequested()

        // The preview: the map, the whole title, the state and size.
        Item {
            id: preview
            width: layout.previewWidth
            readonly property int pad: Tokens.px(24, root.s)
            readonly property int frame: Tokens.line(2, root.s)
            readonly property int textY: map.y + map.height + Tokens.px(18, root.s)
            height: textY + Math.max(Tokens.px(100, root.s), Math.ceil(description.implicitHeight)) + pad
                    + (card.footer !== "" ? Tokens.px(40, root.s) : 0)

            Card {
                id: card
                anchors.fill: parent
                s: root.s
                mark: true
                title: root.cardTitle
                footer: root.cardFoot
            }

            WorkspaceMap {
                id: map
                x: Math.round((preview.width - width) / 2)
                y: card.headerH + preview.pad
                s: root.s
                monitor: root.monitorOfItem
                bar: Settings.barHeight
                windows: root.mapWindows
                selected: root.item ? root.item.id : ""
            }

            Label {
                id: description
                x: preview.pad
                y: preview.textY
                width: preview.width - 2 * preview.pad
                s: root.s
                role: "standard"
                font.weight: Font.Medium
                font.variableAxes: ({ "wght": Font.Medium })
                lineHeightMode: Text.FixedHeight
                lineHeight: Math.round(size * 1.45)
                wrapMode: Text.Wrap
                text: root.cardText
                color: root.error !== "" ? Tokens.color.alert : Tokens.color.darkGray
            }
        }
    }
}
