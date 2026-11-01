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
import "pause"
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

    // spec 013, front D: the entry sound, once per login (Sounds.sessionStart, research S5). A moment
    // after the start so the desktop is up; not with fixtures (frozen screenshots).
    Timer {
        interval: 700
        running: !Fixtures.active
        onTriggered: Sounds.sessionStart()
    }

    // The desktop background, one per monitor (US4). The arcs and bundles drift through one
    // cycle every ~10 min, advanced 10 times a second; the layers only move on whole pixels,
    // so most steps change nothing on screen. Stopped by fixtures, by `wallpaperMotion: false`
    // in shell.json, or over IPC.
    property var wallpaperMotionOverride: null   // IPC: true/false; null = follow Settings
    // spec 013, front A (FR-011): still while a menu is open, as the game's background.
    readonly property bool wallpaperMoving: !Tokens.frozen
        && (wallpaperMotionOverride ?? Settings.wallpaperMotion)
        && !(pauseOpen || pickerOpen || logOpen)
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

    // --- spec 007: the pause menu (U3), with the settings of spec 003 in its SYSTEM tab ----------
    // Opens on the focused monitor (re-read first, research R3 of 003) and stays there until it
    // closes; closing is two-step (it hides and drops the keyboard at once, and is unloaded a
    // moment later). `pauseTab` is the open tab; `pauseLastTab` the one the general shortcut opens
    // (APPS at first). Only one pop-up at a time: the pause menu, the wallpaper picker and the text
    // log (spec 008) close each other.
    property bool pauseOpen: false
    property bool pauseOpening: false
    property bool pauseLoaded: false
    property string pauseMonitor: ""
    property string pauseTab: "apps"
    property string pauseLastTab: "apps"
    property string pausePendingQuery: ""        // `pause search` before the menu is up
    property int settingsCategory: 0             // where SYSTEM reopens
    property var pauseLast: null                 // the closed menu's last `pause dump`
    // spec 013 (research R7): `pause fps start|stop`, the frame times (ms) of the menu's window.
    property bool fpsOn: false
    property var fpsTimes: []
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
        interval: 150 + Tokens.motion.popupClose     // spec 013, front A: the closing triangles first
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
            onTabChanged: {
                shell.pauseTab = tab;
                shell.pauseLastTab = tab;
            }
            onCloseRequested: shell.closePause()
            Component.onCompleted: if (shell.pausePendingQuery !== "") search(shell.pausePendingQuery)
            countFrames: shell.fpsOn
            onFrame: ms => shell.fpsTimes.push(ms)
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
                shell.pauseLastAction = { kind: "window", id: w.id, detail: { op: w.kind, workspace: w.workspace } };
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
    // Like the pause menu: it opens on the focused monitor (re-read first) and stays there until it
    // closes; closing is two-step. Only one of the pop-ups (pause, picker, log) is open at a time.
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
        interval: 150 + Tokens.motion.popupClose     // spec 013, front A: the closing triangles first
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
            // spec 013, front B (R5): a layer kept from before the full-screen menu opened is below it; a
            // wanted one that lingers is brought up as a new surface (the last one created is on top).
            property bool bounce: false
            property bool behind: false          // loaded before the menu: under it
            function bringFront(): void {
                if (!loaded || !behind)
                    return;
                behind = false;
                bounce = true;
                bounceBack.restart();
            }
            Timer {
                id: bounceBack
                interval: 60
                onTriggered: notifySlot.bounce = false
            }
            onWantedChanged: {
                if (wanted) {
                    linger.stop();
                    if (shell.menuCover)
                        bringFront();
                    loaded = true;
                } else {
                    linger.restart();
                }
            }
            Component.onCompleted: loaded = wanted
            Timer {
                id: linger
                interval: Tokens.notify.fade + 150
                onTriggered: if (!notifySlot.wanted) {
                    notifySlot.loaded = false;
                    notifySlot.behind = false;
                }
            }
            LazyLoader {
                id: notifyLoader
                active: notifySlot.loaded && !notifySlot.bounce
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
    // spec 013, front B (R5, FR-014): over a full-screen menu (the pause menu or the wallpaper picker)
    // the critical band, the toasts and the OSD stay on top. Overlay surfaces stack in the order they
    // were created, so when such a menu opens (or the presentation switches to full screen) the ones
    // already up are recreated after it; the ones that appear later are born on top.
    readonly property bool menuCover: Settings.menuPresentation === "fullscreen" && (pauseOpen || pickerOpen)
    onMenuCoverChanged: {
        if (!menuCover)
            return;
        for (const slot of notifyLayers.instances)
            slot.behind = slot.loaded;
        osdBehind = osdLoaded;
        frontTimer.restart();
    }
    Timer {
        id: frontTimer
        interval: 150
        onTriggered: {
            for (const slot of notifyLayers.instances)
                slot.bringFront();
            shell.bringOsdFront();
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
    property bool osdBounce: false               // spec 013, front B: recreated over a full-screen menu
    property bool osdBehind: false
    function bringOsdFront(): void {
        if (!osdLoaded || !osdBehind)
            return;
        osdBehind = false;
        osdBounce = true;
        osdBounceBack.restart();
    }
    Timer {
        id: osdBounceBack
        interval: 60
        onTriggered: shell.osdBounce = false
    }
    Connections {
        target: Osd
        function onCurrentChanged(): void {
            if (Osd.current) {
                shell.osdLast = Osd.current;
                osdUnload.stop();
                if (shell.menuCover)
                    shell.bringOsdFront();
                shell.osdLoaded = true;
            } else {
                osdUnload.restart();
            }
        }
    }
    Timer {
        id: osdUnload
        interval: Tokens.notify.fade + 100
        onTriggered: if (!Osd.current) {
            shell.osdLoaded = false;
            shell.osdBehind = false;
        }
    }
    readonly property var osdItem: osdLoader.item      // a var: qmllint types a LazyLoader's item as QObject
    LazyLoader {
        id: osdLoader
        active: shell.osdLoaded && !shell.osdBounce
        OsdWindow {
            modelData: shell.screenNamed(shell.osdLast?.monitor ?? "")
            osd: shell.osdLast
            shown: Osd.current !== null
            topInset: shell.critBottomOn(shell.osdLast?.monitor ?? "")
        }
    }

    // --- spec 008: log ----------------------------------------------------------------------------
    // spec 013, front B (US8, FR-034): the text log is the pause menu's LOG tab, its only place. While
    // the menu shows that tab the store knows (NotifyStore.logOpen: new ones go to its list, opening
    // marks everything read, and leaving or closing takes the NEW tags off).
    readonly property bool logOpen: pauseOpen && pauseTab === "log"
    readonly property bool logOpening: pauseOpening && pauseTab === "log"
    Binding {
        target: NotifyStore
        property: "logOpen"
        value: shell.logOpen
    }
    function openLog(): void {
        openPause("log");
    }
    function closeLog(): void {
        if (logOpen || logOpening)
            closePause();
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

    // spec 007 (specs/007-menu-de-pausa/contracts/ipc.md): the pause menu.
    IpcHandler {
        target: "pause"
        // Already open (or opening): nothing.
        function open(): void {
            if (!shell.pauseOpen && !shell.pauseOpening)
                shell.openPause(shell.pauseLastTab);
        }
        function close(): void { shell.closePause(); }
        function toggle(): void { shell.togglePause(); }
        function tab(name: string): string {
            if (!["apps", "windows", "log", "system", "power"].includes(name))
                return `error: unknown tab ${name} (apps, windows, log, system or power)`;
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
        // spec 013 (research R7), tests only: `start` clears and starts counting the menu's frames
        // (also across opening and closing); `stop` gives { frames, seconds, mean, p95, p95Ms,
        // worstMs }: mean and p95 in frames per second (p95: what 95% of the frames reach).
        function fps(cmd: string): string {
            if (cmd === "start") {
                shell.fpsTimes = [];
                shell.fpsOn = true;
                return "ok";
            }
            if (cmd !== "stop")
                return `error: unknown command ${cmd} (start or stop)`;
            shell.fpsOn = false;
            const t = shell.fpsTimes.slice().sort((a, b) => a - b);
            const n = t.length;
            const total = t.reduce((a, b) => a + b, 0);
            const p95Ms = n ? t[Math.min(n - 1, Math.ceil(n * 0.95) - 1)] : 0;
            const r = v => Math.round(v * 10) / 10;
            return JSON.stringify({
                frames: n,
                seconds: r(total / 1000),
                mean: total > 0 ? r(n * 1000 / total) : 0,
                p95: p95Ms > 0 ? r(1000 / p95Ms) : 0,
                p95Ms: r(p95Ms),
                worstMs: n ? r(t[n - 1]) : 0
            });
        }
        // spec 013 (front C), tests only: the choice pop-up of the option with the focus on SYSTEM.
        // `open`; `pick <i>` (a single choice); `toggle <i>` (a multiple one); `close`.
        function choice(cmd: string, arg: string): string {
            if (!shell.pauseMenu || !shell.pauseOpen)
                return "error: the menu is closed";
            return shell.pauseMenu.choiceCommand(cmd, arg);
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
                lastAction: shell.pauseLastAction,
                compositor: { backend: Compositor.backendName, capabilities: Compositor.capabilities },
                // spec 013: a closed menu shows the presentation it would open in, and no animation
                presentation: live ? d.presentation : Settings.menuPresentation,
                anim: live ? d.anim : "idle",
                choice: live ? d.choice : null
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
        // spec 013 (contracts/ipc.md): a shell setting by key (Settings.keys, e.g.
        // shell.menuPresentation, sound.volume, input.kbLayouts, and shell.barContrast). `value` is
        // read as JSON when it parses (true, 40), else as text; a list is comma-separated ("us,br":
        // `qs ipc call` does not pass brackets through); "null" goes back to the config. Takes
        // effect at once, as from the menus.
        function set(key: string, value: string): string {
            let v = value;
            try {
                v = JSON.parse(value);
            } catch (e) {
            }
            if (key === "shell.barContrast" || key === "barContrast") {
                if (v !== null && !Settings.barContrastLevels.includes(v))
                    return `error: not a value of shell.barContrast: ${value}`;
                Settings.setLevel("barContrast", v ?? "");
                return "ok";
            }
            const k = Settings.keyOf(key);
            if (Settings.keys[k]?.type === "layouts" && typeof v === "string")
                v = v.split(",").map(x => x.trim()).filter(x => x !== "");
            const err = Settings.setKey(k || key, v);
            return err === "" ? "ok" : `error: ${err}`;
        }
        function dump(): string {
            const open = shell.pauseOpen && shell.pauseTab === "system";
            const page = shell.pauseMenu ? shell.pauseMenu.systemDump() : shell.settingsLast;
            return JSON.stringify({
                live: SettingsModel.liveIds(),       // spec 008: the options that really apply
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
                // spec 013: the shell settings by key (Settings.keys), as `settings set` takes them
                shellValues: Object.keys(Settings.keys).reduce((o, k) => (o[k] = Settings.valueOf(k), o), {}),
                dimmed: SettingsModel.dimmedIds(),
                geometry: open ? page.geometry : null
            });
        }
    }

    // spec 013 (contracts/ipc.md): the interface sounds.
    IpcHandler {
        target: "sounds"
        function play(event: string): string { return Sounds.play(event); }
        function dump(): string { return JSON.stringify(Sounds.dump()); }
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
        // spec 013 (contracts/ipc.md): shortcuts to the pause menu on its LOG tab.
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
                t.controls = b?.controls ?? null;
            }
            if (d.critical) {
                d.critical.box = boxes[d.critical.monitor]?.critical ?? null;
                d.critical.controls = boxes[d.critical.monitor]?.controls ?? null;
            }
            d.more = Object.values(boxes).map(b => b.stack.find(x => x.id === "more")).find(x => x) ?? null;
            d.osd = Osd.dump();
            const osdWin = shell.osdLoaded ? shell.osdItem : null;
            if (d.osd && osdWin)
                d.osd.box = osdWin.box();
            d.osd = d.osd ? Object.assign(d.osd, { position: NotifyPrefs.osdPosition }) : null;
            d.page = shell.logOpen ? (shell.pauseMenu?.logDump() ?? null) : null;
            d.windows = Object.keys(boxes);
            return JSON.stringify(d);
        }
    }
}
