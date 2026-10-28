// rien-OS shell: YoRHa design system + HUD (spec 001).
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "ds"
import "gallery"
import "hud"
import "wallpaper"
import "services"
import "pause"

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

    // --- spec 007: the pause menu (U3), with the settings of spec 003 in its SYSTEM tab ----------
    // Opens on the focused monitor (re-read first, research R3 of 003) and stays there until it
    // closes; closing is two-step (it hides and drops the keyboard at once, and is unloaded a
    // moment later). `pauseTab` is the open tab; `pauseLastTab` the one the general shortcut opens
    // (APPS at first). Only one pop-up at a time: the pause menu and the wallpaper picker close
    // each other.
    property bool pauseOpen: false
    property bool pauseOpening: false
    property bool pauseLoaded: false
    property string pauseMonitor: ""
    property string pauseTab: "apps"
    property string pauseLastTab: "apps"
    property string pausePendingQuery: ""        // `pause search` before the menu is up
    property int settingsCategory: 0             // where SYSTEM reopens
    property var pauseLast: null                 // the closed menu's last `pause dump`
    property var settingsLast: ({})              // the SYSTEM page's last state, for `settings dump`
    property var pauseLastAction: null           // { kind, id, detail }
    readonly property var pauseScreen: {
        for (const sc of Quickshell.screens)
            if (sc.name === pauseMonitor)
                return sc;
        return Quickshell.screens[0] ?? null;
    }
    readonly property var pauseMenu: pauseOpen ? pauseLoader.item : null

    // Open the menu in tab `tab`, or switch an open one to it.
    function openPause(tab: string): void {
        if (pauseOpen) {
            pauseLoader.item?.setTab(tab);
            return;
        }
        pauseTab = tab;
        if (pauseOpening)
            return;
        closePicker();
        pauseOpening = true;
        Compositor.refreshFocusedMonitor();
        pauseFallback.restart();
    }
    // Called when the monitor query is back (or after the fallback, if it never comes).
    function showPause(): void {
        if (!pauseOpening)
            return;
        pauseOpening = false;
        pauseFallback.stop();
        pauseMonitor = Compositor.focusedMonitor;
        pauseOpen = true;
    }
    function closePause(): void {
        pauseOpening = false;
        pauseOpen = false;
    }
    function togglePause(): void {
        if (pauseOpen || pauseOpening)
            closePause();
        else
            openPause(pauseLastTab);
    }
    Connections {
        target: Compositor
        function onMonitorScalesChanged(): void {
            shell.showPause();
        }
    }
    Timer {
        id: pauseFallback
        interval: 250
        onTriggered: shell.showPause()
    }

    onPauseOpenChanged: {
        if (pauseOpen) {
            pauseUnload.stop();
            pauseLoaded = true;
            pauseLoader.item?.setTab(pauseTab);
        } else {
            const menu = pauseLoader.item;
            if (menu) {
                pauseLastTab = menu.tab;
                pauseLast = menu.dumpState();
                pauseLast.open = false;
                pauseLast.geometry = null;
                settingsLast = menu.systemDump();
            }
            pausePendingQuery = "";
            pauseUnload.restart();
        }
    }
    Timer {
        id: pauseUnload
        interval: 150
        onTriggered: if (!shell.pauseOpen) shell.pauseLoaded = false
    }
    LazyLoader {
        id: pauseLoader
        active: shell.pauseLoaded
        PauseMenu {
            screen: shell.pauseScreen
            keyboardActive: shell.pauseOpen
            tab: shell.pauseTab
            systemCategory: shell.settingsCategory
            onSystemCategoryChanged: shell.settingsCategory = systemCategory
            onTabChanged: shell.pauseTab = tab
            onCloseRequested: shell.closePause()
            Component.onCompleted: if (shell.pausePendingQuery !== "") search(shell.pausePendingQuery)
        }
    }

    // The last thing the menu did, from whichever service did it (for `pause dump`).
    Connections {
        target: Apps
        function onLastLaunchChanged(): void {
            const l = Apps.lastLaunch;
            if (l)
                shell.pauseLastAction = { kind: "app", id: l.id, detail: { action: l.action, workspace: l.workspace, ok: l.ok, reason: l.reason } };
        }
    }
    Connections {
        target: Compositor
        function onLastWindowActionChanged(): void {
            const w = Compositor.lastWindowAction;
            if (w)
                shell.pauseLastAction = { kind: "window", id: w.address, detail: { op: w.kind, workspace: w.workspace } };
        }
    }
    Connections {
        target: Session
        function onLastActionChanged(): void {
            const a = Session.lastAction;
            if (a)
                shell.pauseLastAction = { kind: "power", id: a.id, detail: { executed: a.executed, ok: a.ok } };
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
        closePause();
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

    // spec 007 (specs/007-menu-de-pausa/contracts/ipc.md): the pause menu.
    IpcHandler {
        target: "pause"
        function open(): void { shell.openPause(shell.pauseLastTab); }
        function close(): void { shell.closePause(); }
        function toggle(): void { shell.togglePause(); }
        function tab(name: string): string {
            if (!["apps", "windows", "system", "power"].includes(name))
                return `error: unknown tab ${name} (apps, windows, system or power)`;
            shell.openPause(name);
            return "ok";
        }
        function isOpen(): string { return shell.pauseOpen ? "true" : "false"; }
        // Tests only: APPS with `text` as its whole search (opened there if needed).
        function search(text: string): string {
            if (shell.pauseOpen && shell.pauseMonitor !== Compositor.focusedMonitor)
                return `error: the menu is open on ${shell.pauseMonitor}`;
            if (shell.pauseMenu) {
                shell.pauseMenu.search(text);
            } else {
                shell.pausePendingQuery = text;
                shell.openPause("apps");
            }
            return "ok";
        }
        // Back to the start, for tests: APPS as the last tab, the cursors and the search forgotten,
        // the dialog closed, no last action, and the test data's windows, pins and uses as in its
        // files. The values of SYSTEM stay (that is `settings reset`).
        function reset(): void {
            shell.pauseLastTab = "apps";
            shell.settingsCategory = 0;
            shell.pauseLast = null;
            shell.pauseLastAction = null;
            Apps.resetFixture();
            Compositor.resetWindowsFixture();
            Session.resetFixture();
            if (shell.pauseMenu) {
                shell.pauseMenu.systemCategory = 0;
                shell.pauseMenu.restart();
            }
        }
        function dump(): string {
            const live = shell.pauseMenu;
            const d = live ? live.dumpState() : (shell.pauseLast ?? {
                open: false, monitor: "", tab: shell.pauseLastTab, geometry: null
            });
            return JSON.stringify(Object.assign({}, d, {
                open: shell.pauseOpen,
                lastTab: shell.pauseLastTab,
                options: {
                    "icons": SettingsModel.choiceId("menu", "icons"),
                    "app-order": SettingsModel.choiceId("menu", "app-order"),
                    "running-app": SettingsModel.choiceId("menu", "running-app"),
                    "confirm": SettingsModel.choiceId("menu", "confirm"),
                    "confirm-start": SettingsModel.choiceId("menu", "confirm-start")
                },
                lastAction: shell.pauseLastAction
            }));
        }
    }

    // spec 003 (specs/003-settings-popup/contracts/ipc.md), now an alias of the SYSTEM tab (spec
    // 007 research R2). `open` is true only with the menu open on SYSTEM.
    IpcHandler {
        target: "settings"
        function open(): void { shell.openPause("system"); }
        function close(): void {
            if (shell.pauseOpen && shell.pauseTab === "system")
                shell.closePause();
        }
        // Closed → opens on SYSTEM; open on another tab → switches to SYSTEM; on SYSTEM → closes.
        function toggle(): void {
            if ((shell.pauseOpen || shell.pauseOpening) && shell.pauseTab === "system")
                shell.closePause();
            else
                shell.openPause("system");
        }
        function isOpen(): string { return shell.pauseOpen && shell.pauseTab === "system" ? "true" : "false"; }
        // Values back to the catalog and SYSTEM back to its first category, so a test always
        // starts from the same place.
        function reset(): void {
            SettingsModel.reset();
            shell.settingsCategory = 0;
            shell.settingsLast = {};
            if (shell.pauseMenu) {
                shell.pauseMenu.systemCategory = 0;
                shell.pauseMenu.restartSystem(0);
            }
        }
        function dump(): string {
            const open = shell.pauseOpen && shell.pauseTab === "system";
            const page = shell.pauseMenu ? shell.pauseMenu.systemDump() : shell.settingsLast;
            return JSON.stringify({
                open: open,
                monitor: shell.pauseMonitor,
                focus: page.focus ?? "categories",
                category: page.category ?? (SettingsModel.categories[shell.settingsCategory]?.id ?? ""),
                option: page.option ?? null,
                busy: SettingsModel.busy,
                error: SettingsModel.error,
                keys: page.keys ?? [],
                card: page.card ?? { title: "", note: "" },
                values: SettingsModel.dumpValues(),
                dimmed: SettingsModel.dimmedIds(),
                geometry: open ? page.geometry : null
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
}
