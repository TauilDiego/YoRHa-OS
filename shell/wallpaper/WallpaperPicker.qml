pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../ds"
import "../ds/composites"
import "../popup"
import "../services"
import "../strings"

// The wallpaper picker (spec 004 US2, FR-006–FR-009): the PopupWindow titled "WALLPAPER -Select"
// with the PickerLayout:
//   list     the catalog in its groups (SCENES, IMAGES, VIDEO), each item marked with where it is
//            on ("● ALL", or the outputs); with no picture, IMAGES says where to put them;
//   preview  the live PreviewCard of the item with the cursor;
//   options  Monitor (All monitors, then each output), Transition and, for a picture, Paper
//            filter; then Type, Layers, Motion and Now on.
// Enter (or a click) applies the item on the chosen monitor, or on all of them, with the chosen
// transition; the transition and the paper filter take effect as soon as they change. Opens with
// the cursor on what its monitor shows. shell.qml picks the screen and unloads it after closing.
// Amendment (4), FR-032: the Monitor field opens with the user's last choice, saved in SettingsState
// ("wallpaper.pickerMonitor"); an output that isn't connected opens as All monitors. With fixtures
// the saved choice is neither read nor written: the field always opens on All monitors.
PopupWindow {
    id: root

    property real phase: 0

    signal closeRequested()

    readonly property var screens: Quickshell.screens
    readonly property string screenName: screen?.name ?? ""
    readonly property real dpr: Tokens.scaleOf(screenName)
    readonly property var kinds: Settings.transitionKinds
    readonly property var ws: Strings.wallpaper

    // The items in the list's order (the groups, each in the catalog's order).
    readonly property var groups: [ws.scenes, ws.images, ws.video]
    readonly property var items: {
        const all = WallpaperCatalog.items;
        return groups.reduce((out, g) => out.concat(all.filter(w => w.group === g)), []);
    }

    // The cursor follows an id, so a picture added or removed meanwhile doesn't move it.
    property string currentId: ""
    readonly property int index: Math.max(0, items.findIndex(w => w.id === currentId))
    readonly property var item: items[index] ?? null
    // The Monitor field follows an output name ("" = all monitors), so an output plugged or
    // unplugged meanwhile doesn't move it; `monitor` is its value: 0 = all, then `screens` in order.
    property string monitorName: ""
    readonly property int monitor: screens.findIndex(sc => sc.name === monitorName) + 1
    readonly property string monitorKey: "wallpaper.pickerMonitor"

    onIndexChanged: layout.index = index

    // The saved Monitor choice, if its output is connected (never with fixtures).
    function savedMonitor(): string {
        if (!SettingsState.persisted)
            return "";
        const name = SettingsState.get(monitorKey, "all");
        return typeof name === "string" && screens.some(sc => sc.name === name) ? name : "";
    }

    function restart(): void {
        monitorName = savedMonitor();
        currentId = WallpaperStore.resolve(screenName) || (items[0]?.id ?? "");
        layout.restart(index);
    }

    // Where a wallpaper is on: the outputs that show it.
    function shownOn(id: string): var {
        return screens.filter(sc => WallpaperStore.resolve(sc.name) === id).map(sc => sc.name);
    }

    function markOf(id: string): string {
        const on = shownOn(id);
        if (on.length === 0)
            return "";
        return ws.mark + " " + (on.length === screens.length ? ws.all : on.join(" "));
    }

    readonly property string folderShown: {
        const home = Quickshell.env("HOME") || "";
        const f = WallpaperCatalog.folder;
        return home && f.startsWith(home + "/") ? "~" + f.slice(home.length) : f;
    }

    readonly property var entries: {
        const out = [];
        for (const g of groups) {
            out.push({ group: g });
            const inGroup = items.filter(w => w.group === g);
            if (g === ws.images && inGroup.length === 0)
                out.push({ note: ws.emptyFolder.arg(folderShown) });
            for (const w of inGroup)
                out.push({ label: w.name, trailing: markOf(w.id), dim: !w.available });
        }
        return out;
    }

    readonly property bool isPicture: item?.type === "image"
    readonly property bool filterOn: isPicture && !WallpaperStore.paperFilterOff.includes(item.path)

    readonly property var options: {
        const out = [
            { id: "monitor", label: ws.monitor, values: [ws.allMonitors].concat(screens.map(sc => sc.name)) },
            { id: "transition", label: ws.transition, values: kinds.map(k => ws.transitionLabels[k] ?? k) }
        ];
        if (isPicture)
            out.push({ id: "filter", label: ws.paperFilter, values: [ws.on, ws.off] });
        return out;
    }
    readonly property var values: ({
        monitor: monitor,
        transition: Math.max(0, kinds.indexOf(WallpaperStore.transition.kind)),
        filter: filterOn ? 0 : 1
    })

    readonly property var info: {
        const w = item;
        if (!w)
            return [];
        let layers = ws.none, motion = ws.motionNone;
        if (w.type === "scene") {
            const sc = w.scene ?? {}, l = sc.layers ?? {};
            layers = [sc.kind === "dark" ? ws.layerDark : ws.layerPaper, l.arcs && ws.layerArcs, l.beams && ws.layerBeams,
                      l.rules && ws.layerRules].filter(Boolean).join(ws.separator);
            motion = l.arcs || l.beams ? ws.motionSlow : ws.motionNone;
        } else if (w.type === "image") {
            layers = filterOn ? ws.layerPicture : ws.layerPictureRaw;
        }
        const on = shownOn(w.id);
        return [
            { label: ws.type, value: ws.typeLabels[w.type] ?? "" },
            { label: ws.layers, value: layers },
            { label: ws.motion, value: motion },
            { label: ws.nowOn, value: on.length > 0 ? on.join(ws.listSeparator) : ws.none }
        ];
    }

    function applyItem(i: int): void {
        const w = items[i];
        if (!w?.available)
            return;
        currentId = w.id;
        const r = WallpaperStore.set(w.id, monitor === 0 ? "all" : monitorName);
        if (r !== "ok")
            console.info(`wallpaper picker: ${r}`);
    }

    function pick(o: int, v: int): void {
        switch (options[o]?.id) {
        case "monitor":
            monitorName = v === 0 ? "" : (screens[v - 1]?.name ?? "");
            if (SettingsState.persisted)
                SettingsState.set(monitorKey, monitorName || "all");
            break;
        case "transition":
            WallpaperStore.setTransition(kinds[v]);
            break;
        case "filter":
            WallpaperStore.setPaperFilter(item.path, v === 0);
            break;
        }
    }

    // For `wallpaper dump` (contracts/ipc.md, data-model "Picker").
    function dumpState(): var {
        const o = layout.column === "options" ? layout.option : null;
        return {
            open: true,
            screen: screenName,
            focus: layout.column,
            index: layout.index,
            item: item?.id ?? "",
            option: o,
            optionId: o === null ? null : (options[o]?.id ?? null),
            monitor: options[0].values[values.monitor] ?? "",
            transitionLabel: ws.transitionLabels[WallpaperStore.transition.kind] ?? "",
            filter: isPicture ? (filterOn ? ws.on : ws.off) : null,
            keys: layout.keys.map(k => `${k.key} ${k.label}`),
            preview: { title: item?.name ?? "", text: item?.description ?? "", type: item?.type ?? "" },
            info: info.map(r => `${r.label}: ${r.value}`),
            entries: entries.map(e => e.group ?? e.note ?? (e.label + (e.trailing ? " " + e.trailing : "") + (e.dim ? " (dim)" : ""))),
            geometry: layout.geometry()
        };
    }

    title: ws.title
    subtitle: ws.subtitle
    footerLeft: ws.footer.arg(screens.length === 1 ? ws.oneMonitor : ws.manyMonitors.arg(screens.length))
    keys: layout.keys
    onDismissed: closeRequested()
    // Reopened before it was unloaded: start over, as a fresh one does.
    onKeyboardActiveChanged: if (keyboardActive) restart()
    Component.onCompleted: restart()

    PickerLayout {
        id: layout
        anchors.fill: parent
        s: root.s
        focus: true
        entries: root.entries
        options: root.options
        values: root.values
        info: root.info
        onIndexChanged: root.currentId = root.items[layout.index]?.id ?? root.currentId
        onApplied: i => root.applyItem(i)
        onPicked: (o, v) => root.pick(o, v)
        onCloseRequested: root.closeRequested()

        PreviewCard {
            width: layout.previewWidth
            s: root.s
            wallpaper: root.item
            phase: root.phase
            dpr: root.dpr
            paperFilter: !root.isPicture || root.filterOn
        }
    }
}
