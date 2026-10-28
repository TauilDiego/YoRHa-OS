pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Compositor adapter (specs/007-menu-de-pausa/contracts/compositor.md): the facade, the only thing
// the UI uses. It owns what doesn't depend on the compositor: the fixtures ("workspaces" { existing,
// focused }, "activeWindow", "windows"), the validation of every action, `lastWindowAction`, the
// bar's workspace rule and the revisions. The live state and the actions come from one backend in
// compositor/, chosen once at start-up from the environment and created by a Loader, so only the
// chosen file is loaded (only HyprlandBackend.qml imports Quickshell.Hyprland):
//   1. NIER_COMPOSITOR (hyprland | niri | mango | none) forces one, for tests;
//   2. HYPRLAND_INSTANCE_SIGNATURE → Hyprland;
//   3. NIRI_SOCKET → Niri;
//   4. XDG_CURRENT_DESKTOP containing "mango" → Mango;
//   5. none of them → NullBackend (empty lists, actions refused), with a warning.
// Niri and Mango have no backend yet (study 009, S5): they get the NullBackend, with a warning.
//
// Reactivity: workspacesFor() reads every property it depends on (the backend's workspaces, its
// active workspace, the fixture), so a binding that calls it re-evaluates by itself. `revision`
// also increases on every change, for consumers that cache the result.
Singleton {
    id: root

    // --- the backend -------------------------------------------------------------------------------
    readonly property var backendFiles: ({ hyprland: "HyprlandBackend.qml", none: "NullBackend.qml" })
    readonly property string backendWanted: {
        const forced = String(Quickshell.env("NIER_COMPOSITOR") ?? "").toLowerCase();
        if (forced !== "")
            return forced;
        if (String(Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? "") !== "")
            return "hyprland";
        if (String(Quickshell.env("NIRI_SOCKET") ?? "") !== "")
            return "niri";
        if (/mango/i.test(String(Quickshell.env("XDG_CURRENT_DESKTOP") ?? "")))
            return "mango";
        return "none";
    }
    readonly property string backendFile: backendFiles[backendWanted] ?? backendFiles.none
    readonly property var backend: backendLoader.item
    readonly property string backendName: backend?.name ?? "none"

    // What the compositor can do (contracts/compositor.md §3). Under the "windows" fixture,
    // Hyprland's, so the reference images don't depend on the session the tests run in.
    readonly property var hyprlandCapabilities: ({
        workspaceModel: "numbered", canFloat: true, canMoveToWorkspace: true,
        actsOnAnyWindow: true, hasGeometry: "rect", fullscreenKnown: true
    })
    readonly property var capabilities: fixedWindows ? hyprlandCapabilities : (backend?.capabilities ?? ({
        workspaceModel: "numbered", canFloat: false, canMoveToWorkspace: false,
        actsOnAnyWindow: false, hasGeometry: "none", fullscreenKnown: false
    }))

    Loader {
        id: backendLoader
        source: Qt.resolvedUrl(`compositor/${root.backendFile}`)
        // A warning when the session's compositor has no backend (or none was found); forcing
        // "none" on purpose (NIER_COMPOSITOR=none, tests) is only noted.
        onLoaded: {
            const forced = String(Quickshell.env("NIER_COMPOSITOR") ?? "") !== "";
            if (root.backendWanted !== item.name)
                console.warn(`compositor: no backend for "${root.backendWanted}", using "${item.name}" (empty lists, no actions)`);
            else if (item.name === "none" && !forced)
                console.warn("compositor: no known compositor (Hyprland, Niri, Mango), using \"none\" (empty lists, no actions)");
            else
                console.info(`compositor: backend ${item.name}`);
        }
    }

    // The backend's monitors: first the focused one, then the scales, so a handler of
    // monitorScalesChanged (a pop-up waiting to open) already reads the new focusedMonitor.
    Connections {
        target: root.backend
        function onMonitorsChanged(): void {
            const out = {};
            for (const m of root.backend.monitors) {
                out[m.name] = m.scale;
                if (m.focused)
                    root.liveFocusedMonitor = m.name;
            }
            root.monitorScales = out;
        }
        function onChanged(): void {
            root.bump();
        }
    }

    // --- monitors ----------------------------------------------------------------------------------
    readonly property bool fixedWorkspaces: Fixtures.has("workspaces")
    property int fixedFocus: 0          // focus(index) under the fixture; 0 = the fixture's own
    property int revision: 0

    // Each monitor's fractional scale ({ name: scale }): Qt reports only the integer buffer
    // scale, so hairline primitives snap to physical pixels with this (via Tokens.monitorScales).
    // Refreshed at start and on monitor/config events (by the backend).
    property var monitorScales: ({})

    // The output that has the focus. Pop-ups open there. With fixtures, the first screen, so
    // screenshots don't depend on where the pointer is.
    property string liveFocusedMonitor: ""
    readonly property string focusedMonitor: Fixtures.active
        ? (Quickshell.screens[0]?.name ?? "")
        : liveFocusedMonitor

    // Re-read the monitors now (e.g. right before opening a pop-up).
    function refreshFocusedMonitor(): void {
        backend?.refresh("monitors");
    }

    readonly property string activeTitle: Fixtures.has("activeWindow")
        ? String(Fixtures.get("activeWindow") ?? "")
        : (backend?.activeTitle ?? "")

    // --- the bar's workspaces ----------------------------------------------------------------------
    // Tabs for one monitor, in the shape the bar has always read ({ id, exists, focused, monitor },
    // id = the workspace's index): 1..max(5, highest existing, focused), only indexes ≥ 1. With a
    // "dynamic" model (Niri), only the ones that exist on the monitor, without filling up to 5.
    function workspacesFor(monitorName: string): var {
        let existing = [];
        let focusedId = 0;
        const owner = {};
        const dynamic = !fixedWorkspaces && capabilities.workspaceModel === "dynamic";
        if (fixedWorkspaces) {
            const f = Fixtures.get("workspaces") ?? {};
            existing = (Array.isArray(f.existing) ? f.existing : []).map(Number);
            focusedId = fixedFocus > 0 ? fixedFocus : Number(f.focused) || 0;
        } else if (backend) {
            for (const ws of backend.workspaces) {
                if (ws.index >= 1 && (!dynamic || ws.monitor === monitorName)) {
                    existing.push(ws.index);
                    owner[ws.index] = ws.monitor;
                }
            }
            focusedId = backend.activeIndexOn(monitorName);
        }
        existing = existing.filter(id => Number.isInteger(id) && id >= 1);
        const last = dynamic ? Math.max(0, focusedId, ...existing) : Math.max(5, focusedId, ...existing);
        const list = [];
        for (let id = 1; id <= last; id++) {
            if (dynamic && !existing.includes(id))
                continue;
            list.push({
                id: id,
                exists: existing.includes(id),
                focused: id === focusedId,
                monitor: owner[id] || monitorName
            });
        }
        return list;
    }

    // Go to workspace `index` of the focused monitor; only the fixed focus while the "workspaces"
    // fixture is active.
    function focus(index: int): void {
        if (index < 1)
            return;
        if (fixedWorkspaces) {
            fixedFocus = index;
            return;
        }
        const ws = (backend?.workspaces ?? []).find(w => w.index === index);
        backend?.focusWorkspace(ws ? ws.key : String(index));
    }

    function bump(): void {
        revision++;
    }

    // --- spec 007: windows and workspaces (contracts/services.md, contracts/compositor.md) ---------
    // windows: [Window] { id (opaque; Hyprland: the 0x… address), address (a synonym of id while the
    // pause menu migrates), appClass, title, workspaceKey, workspace (its index, -1 = special),
    // workspaceName, monitor, floating, focused, focusOrder (0 = focused), fullscreen, rect { x, y,
    // w, h } (logical px, relative to the monitor) or null, column or null, and x, y, w, h (rect's,
    // flat) }.
    // Fixture "windows": the path of a file (pause-fixtures.schema.json, windowsFile); its windows
    // live in memory, so the actions change them there and nothing reaches the compositor.
    readonly property bool fixedWindows: Fixtures.has("windows")
    readonly property string windowsFixturePath: fixedWindows ? Fixtures.resolve(String(Fixtures.get("windows") ?? "")) : ""
    property var fixedWindowList: []
    property var fixedMonitorList: []
    property string windowsError: ""
    property int windowsRevision: 0
    property var lastWindowAction: null          // { kind, id, address, workspace }

    readonly property var windows: fixedWindows ? fixedWindowList : (backend?.windows ?? [])
    // [{ name, x, y, w, h (logical), scale, focused }]
    readonly property var monitorList: fixedWindows ? fixedMonitorList : (backend?.monitors ?? [])
    // [Workspace] { key, index, label, monitor, focused, exists, windows: [id] } (id and name too,
    // as synonyms of index and label).
    readonly property var workspaceList: {
        if (!fixedWindows)
            return (backend?.workspaces ?? []).map(ws => Object.assign({ id: ws.index, name: ws.label }, ws));
        const by = {};
        for (const w of fixedWindowList) {
            const key = w.workspaceKey;
            by[key] = by[key] ?? {
                key: key, index: w.workspace, label: w.workspaceName, id: w.workspace, name: w.workspaceName,
                monitor: w.monitor, focused: false, exists: true, windows: []
            };
            by[key].windows.push(w.id);
            if (w.focused)
                by[key].focused = true;
        }
        return Object.values(by).sort((a, b) => (a.index < 0 ? 99 : a.index) - (b.index < 0 ? 99 : b.index));
    }

    onWindowsChanged: if (!fixedWindows) windowsRevision++

    function windowAt(id: string): var {
        return windows.find(w => w.id === id) ?? null;
    }

    // One window object in the shape above, from a fixture entry.
    function fixtureWindow(w: var, i: int): var {
        const ws = Number(w.workspace);
        const rect = { x: Number(w.x) || 0, y: Number(w.y) || 0, w: Math.max(1, Number(w.w) || 1), h: Math.max(1, Number(w.h) || 1) };
        const name = String(w.workspaceName ?? (ws < 0 ? "special" : String(ws)));
        return {
            id: String(w.address), address: String(w.address), appClass: String(w.class ?? ""), title: String(w.title ?? ""),
            workspaceKey: ws < 0 ? name : String(ws), workspace: ws, workspaceName: name,
            monitor: String(w.monitor ?? ""), floating: w.floating === true, focused: w.focused === true,
            focusOrder: w.focused === true ? 0 : i + 1, fullscreen: false,
            rect: rect, column: null, x: rect.x, y: rect.y, w: rect.w, h: rect.h
        };
    }

    function loadWindowsFixture(text: string): void {
        try {
            const d = JSON.parse(text);
            if (!Array.isArray(d?.monitors) || d.monitors.length === 0 || !Array.isArray(d.windows))
                throw new Error("needs monitors and windows");
            fixedMonitorList = d.monitors.map(m => ({ name: String(m.name), x: 0, y: 0, w: Number(m.w), h: Number(m.h), scale: 1, focused: m.focused === true }));
            fixedWindowList = d.windows.map((w, i) => fixtureWindow(w, i));
            windowsError = "";
        } catch (e) {
            failWindows(`${windowsFixturePath}: ${e}`);
        }
        windowsRevision++;
    }

    function failWindows(reason: string): void {
        console.warn(`compositor: windows fixture unusable, ${reason}`);
        fixedWindowList = [];
        fixedMonitorList = [];
        windowsError = "unavailable";
    }

    FileView {
        id: windowsFixture
        path: root.windowsFixturePath
        printErrors: false
        blockLoading: true
        onLoaded: root.loadWindowsFixture(text())
        onLoadFailed: root.failWindows(`cannot read ${path}`)
    }
    onFixedWindowsChanged: {
        windowsError = "";
        lastWindowAction = null;
        windowsRevision++;
    }

    // Back to the fixture file's windows (a fixture loaded again, `pause reset`).
    function resetWindowsFixture(): void {
        if (fixedWindows)
            windowsFixture.reload();
        lastWindowAction = null;
    }

    // A fixture window changed in memory (the actions under a fixture).
    function editFixed(id: string, change: var): void {
        fixedWindowList = fixedWindowList.map(w => w.id === id ? Object.assign({}, w, change) : w);
        windowsRevision++;
    }

    // A window the compositor knows, with an id it would accept.
    function known(id: string): var {
        const w = windowAt(id);
        if (!w)
            return null;
        return fixedWindows || (backend?.validId(id) ?? false) ? w : null;
    }

    function note(kind: string, id: string, ws: int): string {
        lastWindowAction = { kind: kind, id: id, address: id, workspace: ws };
        return "ok";
    }

    // Before acting on a window that isn't focused, a backend that only acts on the focused one
    // gets it focused first.
    function prepare(w: var): void {
        if (!capabilities.actsOnAnyWindow && !w.focused)
            backend?.focusWindow(w.id);
    }

    // Go to the window: its workspace, and the focus. Returns "ok" or "error: …".
    function focusWindow(id: string): string {
        const w = known(id);
        if (!w)
            return `error: unknown window ${id}`;
        if (fixedWindows) {
            let order = 1;
            fixedWindowList = fixedWindowList.map(x => Object.assign({}, x, {
                focused: x.id === id, focusOrder: x.id === id ? 0 : order++
            }));
            windowsRevision++;
        } else {
            backend.focusWindow(id);
        }
        return note("focus", id, w.workspace);
    }

    // Move the window to workspace `index` (1–10) of its monitor without following it.
    function moveWindow(id: string, index: int): string {
        const w = known(id);
        if (!w)
            return `error: unknown window ${id}`;
        if (!capabilities.canMoveToWorkspace)
            return "error: unsupported";
        if (!(Number.isInteger(index) && index >= 1 && index <= 10)) {
            console.warn(`compositor: workspace ${index} is not 1–10, nothing sent`);
            return `error: workspace ${index} is not 1–10`;
        }
        if (fixedWindows) {
            editFixed(id, { workspace: index, workspaceKey: String(index), workspaceName: String(index) });
        } else {
            const ws = (backend.workspaces ?? []).find(x => x.index === index && (x.monitor === w.monitor || x.monitor === ""));
            prepare(w);
            backend.moveWindow(id, ws ? ws.key : String(index));
        }
        return note("move", id, index);
    }

    function toggleFloating(id: string): string {
        const w = known(id);
        if (!w)
            return `error: unknown window ${id}`;
        if (!capabilities.canFloat)
            return "error: unsupported";
        if (fixedWindows) {
            editFixed(id, { floating: !w.floating });
        } else {
            prepare(w);
            backend.toggleFloating(id);
        }
        return note("float", id, w.workspace);
    }

    // Ask the window to close (the app may ask first). Under a fixture it is gone at once.
    function closeWindow(id: string): string {
        const w = known(id);
        if (!w)
            return `error: unknown window ${id}`;
        if (fixedWindows) {
            fixedWindowList = fixedWindowList.filter(x => x.id !== id);
            windowsRevision++;
        } else {
            prepare(w);
            backend.closeWindow(id);
        }
        return note("close", id, w.workspace);
    }
    // --- end spec 007 ------------------------------------------------------------------------------

    onFixedWorkspacesChanged: fixedFocus = 0
    onFixedFocusChanged: bump()

    Connections {
        target: Fixtures
        function onDataChanged() {
            root.fixedFocus = 0;
            root.bump();
            root.resetWindowsFixture();
        }
    }
}
