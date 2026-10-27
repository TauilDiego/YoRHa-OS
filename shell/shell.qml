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
import "settings"

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
    Variants {
        id: huds
        model: Quickshell.screens

        Hud {}
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
        // The picker arrives with US2 (it needs spec 003's pop-up pieces).
        function picker(action: string): string { return "ok"; }
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
                picker: null
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
    }
}
