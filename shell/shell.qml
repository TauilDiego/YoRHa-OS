// YoRHa-OS shell: YoRHa design system + HUD (spec 001).
// Launch it with QT_LOGGING_RULES=qt.qpa.wayland.textinput.warning=false. That silences one Qt
// 6.12.0 warning and nothing else: every newly focused pop-up logs "qt.qpa.wayland.textinput: …
// disableSurface … but 0x0 is focused" (QWaylandInputContext disables text input on a surface
// that never enabled it), an upstream bug already fixed in Qt dev. Drop the rule once Arch ships
// a Qt with the fix. It has to be in the environment qs starts with: `//@ pragma Env` sets it too
// late for Quickshell 0.3.2's logger (tried in the lab VM, 2026-10-27).
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "ds"
import "gallery"
import "hud"
import "wallpaper"
import "services"
import "settings"
import "notify"

ShellRoot {
    id: shell

    // Fixtures freeze animations so two screenshots are pixel-identical (SC-002).
    Binding {
        target: Tokens
        property: "frozen"
        value: Fixtures.active
    }

    Binding {
        target: Tokens
        property: "monitorScales"
        value: Compositor.monitorScales
    }

    // spec 003: reduced motion (fades and the selector blink become instant).
    Binding {
        target: Tokens
        property: "reduced"
        value: Settings.reduceMotion
    }

    property bool galleryOpen: false

    // The desktop background, one per monitor (US4). The arcs and bundles drift through one
    // cycle every ~10 min, advanced 10 times a second; the layers only move on whole pixels,
    // so most steps change nothing on screen. Stopped by fixtures, by `wallpaperMotion: false`
    // in shell.json, or over IPC.
    property var wallpaperMotionOverride: null   // IPC: true/false; null = follow Settings
    readonly property bool wallpaperMoving: !Tokens.frozen
        && (wallpaperMotionOverride ?? Settings.wallpaperMotion)
    property real wallpaperPhase: 0
    Timer {
        running: shell.wallpaperMoving
        repeat: true
        interval: 100
        onTriggered: shell.wallpaperPhase = (shell.wallpaperPhase + 1 / 6000) % 1
    }
    Variants {
        id: wallpapers      // spec 004: read by `wallpaper dump`
        model: Quickshell.screens

        Wallpaper {
            phase: shell.wallpaperPhase
        }
    }

    // One HUD per monitor (FR-009).
    // spec 004 US6: `hud visible false` takes the bars off for a moment, so a test can photograph the
    // wallpaper alone under them (the bar's empty area and the contrast of its texts, SC-011/012).
    property bool hudShown: true
    Variants {
        id: huds
        model: Quickshell.screens

        Hud {
            visible: shell.hudShown
            onLogRequested: shell.openLog()      // spec 008: the unread counter
        }
    }

    // The design system gallery (US3): created only while open. A single instance; the
    // compositor puts it on the focused output. Closing happens in two steps: the gallery
    // first gives up its exclusive keyboard focus, and is unloaded a moment later, so Qt's
    // text-input plugin doesn't warn about a focused surface going away.
    property bool galleryLoaded: false
    onGalleryOpenChanged: {
        if (galleryOpen)
            galleryLoaded = true;
        else
            galleryUnload.restart();
    }
    Timer {
        id: galleryUnload
        interval: 150
        onTriggered: if (!shell.galleryOpen) shell.galleryLoaded = false
    }
    LazyLoader {
        active: shell.galleryLoaded
        Gallery {
            keyboardActive: shell.galleryOpen
            onCloseRequested: shell.galleryOpen = false
        }
    }

    // --- spec 003: settings pop-up -------------------------------------------------------------
    // Opens on the focused monitor and stays there until it closes; opening re-reads the
    // focused monitor first (research R3). Closing is two-step, like the gallery (research R2):
    // the pop-up hides and drops its keyboard focus at once, and is unloaded a moment later.
    property bool settingsOpen: false
    property bool settingsOpening: false
    property bool settingsLoaded: false
    property string settingsMonitor: ""
    property int settingsCategory: 0             // where the pop-up reopens
    property var settingsLast: ({})              // the closed pop-up's last state, for `dump`
    readonly property var settingsScreen: {
        for (const sc of Quickshell.screens)
            if (sc.name === settingsMonitor)
                return sc;
        return Quickshell.screens[0] ?? null;
    }

    function openSettings(): void {
        if (settingsOpen || settingsOpening)
            return;
        settingsOpening = true;
        Compositor.refreshFocusedMonitor();
        settingsFallback.restart();
    }
    // Called when the monitor query is back (or after the fallback, if it never comes).
    function showSettings(): void {
        if (!settingsOpening)
            return;
        settingsOpening = false;
        settingsFallback.stop();
        settingsMonitor = Compositor.focusedMonitor;
        settingsOpen = true;
    }
    function closeSettings(): void {
        settingsOpening = false;
        settingsOpen = false;
    }
    Connections {
        target: Compositor
        function onMonitorScalesChanged(): void {
            shell.showSettings();
        }
    }
    Timer {
        id: settingsFallback
        interval: 250
        onTriggered: shell.showSettings()
    }

    onSettingsOpenChanged: {
        if (settingsOpen) {
            settingsUnload.stop();
            settingsLoaded = true;
        } else {
            settingsLast = settingsLoader.item?.dumpState() ?? settingsLast;
            settingsUnload.restart();
        }
    }
    Timer {
        id: settingsUnload
        interval: 150
        onTriggered: if (!shell.settingsOpen) shell.settingsLoaded = false
    }
    LazyLoader {
        id: settingsLoader
        active: shell.settingsLoaded
        SettingsPopup {
            screen: shell.settingsScreen
            keyboardActive: shell.settingsOpen
            category: shell.settingsCategory
            onCategoryChanged: shell.settingsCategory = category
            onCloseRequested: shell.closeSettings()
        }
    }

    // --- spec 004: wallpaper picker (US2) ------------------------------------------------------
    // Like the settings pop-up: it opens on the focused monitor (re-read first) and stays there
    // until it closes; closing is two-step. Only one of the two pop-ups is open at a time.
    property bool pickerOpen: false
    property bool pickerOpening: false
    property bool pickerLoaded: false
    property string pickerMonitor: ""
    readonly property var pickerScreen: {
        for (const sc of Quickshell.screens)
            if (sc.name === pickerMonitor)
                return sc;
        return Quickshell.screens[0] ?? null;
    }

    function openPicker(): void {
        if (pickerOpen || pickerOpening)
            return;
        closeSettings();
        pickerOpening = true;
        Compositor.refreshFocusedMonitor();
        pickerFallback.restart();
    }
    function showPicker(): void {
        if (!pickerOpening)
            return;
        pickerOpening = false;
        pickerFallback.stop();
        pickerMonitor = Compositor.focusedMonitor;
        pickerOpen = true;
    }
    function closePicker(): void {
        pickerOpening = false;
        pickerOpen = false;
    }
    Connections {
        target: Compositor
        function onMonitorScalesChanged(): void {
            shell.showPicker();
        }
    }
    Connections {
        target: shell
        function onSettingsOpenChanged(): void {
            if (shell.settingsOpen)
                shell.closePicker();
        }
    }
    Timer {
        id: pickerFallback
        interval: 250
        onTriggered: shell.showPicker()
    }

    onPickerOpenChanged: {
        if (pickerOpen) {
            pickerUnload.stop();
            pickerLoaded = true;
        } else {
            pickerUnload.restart();
        }
    }
    Timer {
        id: pickerUnload
        interval: 150
        onTriggered: if (!shell.pickerOpen) shell.pickerLoaded = false
    }
    LazyLoader {
        id: pickerLoader
        active: shell.pickerLoaded
        WallpaperPicker {
            screen: shell.pickerScreen
            keyboardActive: shell.pickerOpen
            phase: shell.wallpaperPhase
            onCloseRequested: shell.closePicker()
        }
    }
    // --- end spec 004 ---------------------------------------------------------------------------

    // --- spec 008: transmissions ------------------------------------------------------------------
    // One NotifyLayer per monitor, created only while that monitor shows something (research R9) and
    // kept a moment after, so the last one can fade out.
    function screenNamed(name: string): var {
        for (const sc of Quickshell.screens)
            if (sc.name === name)
                return sc;
        return Quickshell.screens[0] ?? null;
    }
    Variants {
        id: notifyLayers
        model: Quickshell.screens

        Scope {
            id: notifySlot
            required property var modelData
            readonly property string name: modelData?.name ?? ""
            readonly property bool wanted: NotifyStore.stack.some(t => t.monitor === notifySlot.name)
                || NotifyStore.critical?.monitor === notifySlot.name
            property bool loaded: false
            onWantedChanged: {
                if (wanted) {
                    linger.stop();
                    loaded = true;
                } else {
                    linger.restart();
                }
            }
            Component.onCompleted: loaded = wanted
            Timer {
                id: linger
                interval: Tokens.notify.fade + 150
                onTriggered: if (!notifySlot.wanted) notifySlot.loaded = false
            }
            LazyLoader {
                id: notifyLoader
                active: notifySlot.loaded
                NotifyLayer {
                    modelData: notifySlot.modelData
                    onOpenLogRequested: shell.openLog()
                }
            }
            function dumpBoxes(): var {
                return notifyLoader.item?.dumpBoxes() ?? null;
            }
            readonly property real critBottom: notifyLoader.item?.critBottom ?? 0
        }
    }
    function critBottomOn(name: string): real {
        for (const slot of notifyLayers.instances)
            if (slot.name === name)
                return slot.critBottom;
        return 0;
    }

    // --- spec 008: osd ----------------------------------------------------------------------------
    // The OSD's window exists while there is an OSD, and a moment after (its fade out).
    property var osdLast: null
    property bool osdLoaded: false
    Connections {
        target: Osd
        function onCurrentChanged(): void {
            if (Osd.current) {
                shell.osdLast = Osd.current;
                osdUnload.stop();
                shell.osdLoaded = true;
            } else {
                osdUnload.restart();
            }
        }
    }
    Timer {
        id: osdUnload
        interval: Tokens.notify.fade + 100
        onTriggered: if (!Osd.current) shell.osdLoaded = false
    }
    readonly property var osdItem: osdLoader.item      // a var: qmllint types a LazyLoader's item as QObject
    LazyLoader {
        id: osdLoader
        active: shell.osdLoaded
        OsdWindow {
            modelData: shell.screenNamed(shell.osdLast?.monitor ?? "")
            osd: shell.osdLast
            shown: Osd.current !== null
            topInset: shell.critBottomOn(shell.osdLast?.monitor ?? "")
        }
    }

    // --- spec 008: log ----------------------------------------------------------------------------
    // The text log's pop-up, like the settings and the picker: it opens on the focused monitor (re-read
    // first), closes in two steps, and only one of the three is open at a time. While it shows, the store
    // knows (NotifyStore.logOpen: new ones go to its list, and opening marks everything read).
    property bool logOpen: false
    property bool logOpening: false
    property bool logLoaded: false
    property string logMonitor: ""
    Binding {
        target: NotifyStore
        property: "logOpen"
        value: shell.logOpen
    }
    function openLog(): void {
        if (logOpen || logOpening)
            return;
        closeSettings();
        closePicker();
        logOpening = true;
        Compositor.refreshFocusedMonitor();
        logFallback.restart();
    }
    function showLog(): void {
        if (!logOpening)
            return;
        logOpening = false;
        logFallback.stop();
        logMonitor = Compositor.focusedMonitor;
        logOpen = true;
    }
    function closeLog(): void {
        logOpening = false;
        logOpen = false;
    }
    Connections {
        target: Compositor
        function onMonitorScalesChanged(): void {
            shell.showLog();
        }
    }
    Connections {
        target: shell
        function onSettingsOpenChanged(): void {
            if (shell.settingsOpen)
                shell.closeLog();
        }
        function onPickerOpenChanged(): void {
            if (shell.pickerOpen)
                shell.closeLog();
        }
    }
    Timer {
        id: logFallback
        interval: 250
        onTriggered: shell.showLog()
    }
    onLogOpenChanged: {
        if (logOpen) {
            logUnload.stop();
            logLoaded = true;
        } else {
            logUnload.restart();
        }
    }
    Timer {
        id: logUnload
        interval: 150
        onTriggered: if (!shell.logOpen) shell.logLoaded = false
    }
    readonly property var logItem: logLoader.item
    LazyLoader {
        id: logLoader
        active: shell.logLoaded
        LogPopup {
            screen: shell.screenNamed(shell.logMonitor)
            keyboardActive: shell.logOpen
            onCloseRequested: shell.closeLog()
        }
    }
    // --- end spec 008 -----------------------------------------------------------------------------

    // --- IPC (contracts/ipc.md) ---------------------------------------------------------------
    IpcHandler {
        target: "gallery"
        function open(): void { shell.galleryOpen = true; }
        function close(): void { shell.galleryOpen = false; }
        function toggle(): void { shell.galleryOpen = !shell.galleryOpen; }
        function isOpen(): string { return shell.galleryOpen ? "true" : "false"; }
    }

    IpcHandler {
        target: "fixtures"
        function load(path: string): string { return Fixtures.load(path); }
        function clear(): void { Fixtures.clear(); }
    }

    IpcHandler {
        target: "wallpaper"
        function motion(on: bool): void { shell.wallpaperMotionOverride = on; }
        function isMoving(): string { return shell.wallpaperMoving ? "true" : "false"; }

        // --- spec 004 (contracts/ipc.md): the catalog, the choice per monitor, the transition --
        function list(): string {
            return JSON.stringify(WallpaperCatalog.items.map(w => ({
                id: w.id, type: w.type, name: w.name, group: w.group, available: w.available
            })));
        }
        function set(id: string, monitor: string): string { return WallpaperStore.set(id, monitor); }
        function next(monitor: string): string { return WallpaperStore.step(monitor, 1); }
        function prev(monitor: string): string { return WallpaperStore.step(monitor, -1); }
        function transition(kind: string): string { return WallpaperStore.setTransition(kind); }
        function camouflage(cell: int, trail: int, glitch: int): string {
            return WallpaperStore.setCamouflage(cell, trail, glitch);
        }
        function filter(path: string, on: bool): string { return WallpaperStore.setPaperFilter(path, on); }
        function picker(action: string): string {
            switch (action) {
            case "open":
                shell.openPicker();
                return "ok";
            case "close":
                shell.closePicker();
                return "ok";
            case "toggle":
                if (shell.pickerOpen || shell.pickerOpening)
                    shell.closePicker();
                else
                    shell.openPicker();
                return "ok";
            }
            return "error: picker takes open, close or toggle";
        }
        function dump(): string {
            return JSON.stringify({
                all: WallpaperStore.all,
                monitors: wallpapers.instances.map(w => w.dumpEntry()),
                transition: Object.assign({}, WallpaperStore.transition, { instant: WallpaperStore.instant }),
                catalog: {
                    count: WallpaperCatalog.count,
                    folder: WallpaperCatalog.folder,
                    folderMissing: WallpaperCatalog.folderMissing,
                    ready: WallpaperCatalog.ready
                },
                paperFilterOff: WallpaperStore.paperFilterOff,
                picker: shell.pickerOpen ? (pickerLoader.item?.dumpState() ?? null) : null
            });
        }
        // --- end spec 004 ------------------------------------------------------------------
    }

    // spec 003 (specs/003-settings-popup/contracts/ipc.md)
    IpcHandler {
        target: "settings"
        function open(): void { shell.openSettings(); }
        function close(): void { shell.closeSettings(); }
        function toggle(): void {
            if (shell.settingsOpen || shell.settingsOpening)
                shell.closeSettings();
            else
                shell.openSettings();
        }
        function isOpen(): string { return shell.settingsOpen ? "true" : "false"; }
        // Values back to the catalog and the pop-up back to its first category, so a test
        // always starts from the same place.
        function reset(): void {
            SettingsModel.reset();
            shell.settingsCategory = 0;
            shell.settingsLast = {};
            settingsLoader.item?.restart(0);
        }
        function dump(): string {
            const live = shell.settingsOpen ? settingsLoader.item : null;
            const page = live ? live.dumpState() : shell.settingsLast;
            return JSON.stringify({
                live: SettingsModel.liveIds(),       // spec 008: the options that really apply
                open: shell.settingsOpen,
                monitor: shell.settingsMonitor,
                focus: page.focus ?? "categories",
                category: page.category ?? (SettingsModel.categories[shell.settingsCategory]?.id ?? ""),
                option: page.option ?? null,
                busy: SettingsModel.busy,
                error: SettingsModel.error,
                keys: page.keys ?? [],
                card: page.card ?? { title: "", note: "" },
                values: SettingsModel.dumpValues(),
                dimmed: SettingsModel.dimmedIds(),
                geometry: live ? page.geometry : null
            });
        }
    }

    IpcHandler {
        target: "hud"
        function dump(): string {
            const out = [];
            for (const hud of huds.instances)
                out.push(hud.dumpEntry());
            return JSON.stringify(out);
        }
        // spec 004 US6: hide or show the bars (tests only; nothing remembers it). Not `show`:
        // the qs command line takes that word for its own `ipc show`.
        function visible(on: bool): void { shell.hudShown = on; }
    }

    // --- spec 008 (specs/008-pod-text-log/contracts/ipc.md) -------------------------------------------
    IpcHandler {
        target: "notify"
        function open(): void { shell.openLog(); }
        function close(): void { shell.closeLog(); }
        function toggle(): void {
            if (shell.logOpen || shell.logOpening)
                shell.closeLog();
            else
                shell.openLog();
        }
        function isOpen(): string { return shell.logOpen ? "true" : "false"; }
        function dnd(mode: string): string {
            if (mode === "toggle")
                NotifyPrefs.setDnd(!NotifyPrefs.dnd);
            else if (mode === "on" || mode === "off")
                NotifyPrefs.setDnd(mode === "on");
            else
                return "error: dnd takes on, off or toggle";
            return NotifyPrefs.dnd ? "on" : "off";
        }
        function clear(): string {
            NotifyStore.clear();
            return "ok";
        }
        function dismissAll(): string {
            NotifyStore.hideAll();
            return "ok";
        }
        function invoke(id: int, action: string): string { return NotifyStore.invoke(id, action); }
        function osd(kind: string, value: int, muted: bool): string { return Osd.show(kind, value, muted); }
        function sample(name: string): string { return NotifyStore.sample(name); }
        function pref(key: string, value: string): string { return NotifyPrefs.set(key, value); }
        function prefsReset(): string {
            NotifyPrefs.reset();
            return "ok";
        }
        function dump(): string {
            const d = NotifyStore.dumpState();
            const boxes = {};
            for (const slot of notifyLayers.instances) {
                const b = slot.dumpBoxes();
                if (b)
                    boxes[slot.name] = b;
            }
            for (const t of d.screen) {
                const b = boxes[t.monitor]?.stack.find(x => x.id === t.id);
                t.box = b ? { x: b.x, y: b.y, w: b.w, h: b.h } : null;
            }
            if (d.critical)
                d.critical.box = boxes[d.critical.monitor]?.critical ?? null;
            d.more = Object.values(boxes).map(b => b.stack.find(x => x.id === "more")).find(x => x) ?? null;
            d.osd = Osd.dump();
            const osdWin = shell.osdLoaded ? shell.osdItem : null;
            if (d.osd && osdWin)
                d.osd.box = osdWin.box();
            d.osd = d.osd ? Object.assign(d.osd, { position: NotifyPrefs.osdPosition }) : null;
            const logWin = shell.logOpen ? shell.logItem : null;
            d.page = logWin ? logWin.dumpState() : null;
            d.windows = Object.keys(boxes);
            return JSON.stringify(d);
        }
    }
}
