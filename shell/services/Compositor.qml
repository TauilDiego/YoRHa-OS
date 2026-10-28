pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Compositor adapter (research R1): the ONLY file that imports Quickshell.Hyprland, so Niri
// (S5) is a new Compositor.qml. Fixtures: "workspaces" { existing, focused } (same on every
// monitor; focus() then only moves the fixed focus) and "activeWindow" (title).
//
// Reactivity: workspacesFor() reads every property it depends on (workspace list, ids,
// monitors, active workspaces, fixture), so a binding that calls it re-evaluates by itself.
// `revision` also increases on every change, for consumers that cache the result.
Singleton {
    id: root

    readonly property bool fixedWorkspaces: Fixtures.has("workspaces")
    property int fixedFocus: 0          // focus(id) under the fixture; 0 = the fixture's own
    property int revision: 0

    // Each monitor's fractional scale ({ name: scale }): Qt reports only the integer buffer
    // scale, so hairline primitives snap to physical pixels with this (via Tokens.monitorScales).
    // Read from `hyprctl monitors -j`: Quickshell's Hyprland.monitors stays empty on Hyprland
    // 0.56 with a Lua config. Refreshed at start and on monitor/config events.
    property var monitorScales: ({})

    // The output that has the focus, from the same query (field `focused`). Pop-ups open there.
    // With fixtures, the first screen, so screenshots don't depend on where the pointer is.
    property string liveFocusedMonitor: ""
    readonly property string focusedMonitor: Fixtures.active
        ? (Quickshell.screens[0]?.name ?? "")
        : liveFocusedMonitor

    // Re-read the monitors now (e.g. right before opening a pop-up).
    function refreshFocusedMonitor(): void {
        monitorQuery.running = true;
    }

    Process {
        id: monitorQuery
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const out = {};
                    for (const m of JSON.parse(text)) {
                        out[m.name] = m.scale;
                        if (m.focused)
                            root.liveFocusedMonitor = m.name;
                    }
                    root.monitorScales = out;
                } catch (e) {
                    // keep the last known scales
                }
            }
        }
    }

    readonly property string activeTitle: Fixtures.has("activeWindow")
        ? String(Fixtures.get("activeWindow") ?? "")
        : (Hyprland.activeToplevel?.title ?? startupTitle)

    // Hyprland.activeToplevel stays empty until the first focus event after a (re)start, so
    // the title at startup comes from `hyprctl activewindow -j`.
    property string startupTitle: ""

    Process {
        id: activeWindowQuery
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.startupTitle = JSON.parse(text).title ?? "";
                } catch (e) {
                    root.startupTitle = "";
                }
            }
        }
    }

    // Tabs for one monitor: ids 1..max(5, highest existing id, focused id), only ids ≥ 1.
    function workspacesFor(monitorName: string): var {
        let existing = [];
        let focusedId = 0;
        const owner = {};
        if (fixedWorkspaces) {
            const f = Fixtures.get("workspaces") ?? {};
            existing = (Array.isArray(f.existing) ? f.existing : []).map(Number);
            focusedId = fixedFocus > 0 ? fixedFocus : Number(f.focused) || 0;
        } else {
            for (const ws of Hyprland.workspaces.values) {
                if (ws.id >= 1) {
                    existing.push(ws.id);
                    owner[ws.id] = ws.monitor?.name ?? "";
                }
            }
            const mon = Hyprland.monitors.values.find(m => m.name === monitorName);
            focusedId = (mon ? mon.activeWorkspace?.id : Hyprland.focusedWorkspace?.id) ?? 0;
        }
        existing = existing.filter(id => Number.isInteger(id) && id >= 1);
        const last = Math.max(5, focusedId, ...existing);
        const list = [];
        for (let id = 1; id <= last; id++) {
            list.push({
                id: id,
                exists: existing.includes(id),
                focused: id === focusedId,
                monitor: owner[id] || monitorName
            });
        }
        return list;
    }

    // Real switch, or only the fixed focus while the "workspaces" fixture is active.
    function focus(id: int): void {
        if (id < 1)
            return;
        if (fixedWorkspaces) {
            fixedFocus = id;
            return;
        }
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        if (ws)
            ws.activate();
        else if (Hyprland.usingLua)     // a Lua config takes a Lua dispatcher expression
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    function bump(): void {
        revision++;
    }

    // --- spec 007: windows and workspaces (contracts/services.md, research R7/R8) ------------------
    // windows: [{ address, appClass, title, workspace (-1 = special), workspaceName, monitor, x, y, w,
    // h (logical px, relative to the monitor), floating, focused, focusOrder (0 = focused) }].
    // Fixture "windows": the path of a file (pause-fixtures.schema.json, windowsFile); its windows
    // live in memory, so the actions change them there and nothing reaches the compositor.
    readonly property bool fixedWindows: Fixtures.has("windows")
    readonly property string windowsFixturePath: fixedWindows ? Fixtures.resolve(String(Fixtures.get("windows") ?? "")) : ""
    property var fixedWindowList: []
    property var fixedMonitorList: []
    property string windowsError: ""
    property var liveWindows: []
    property var liveWorkspaces: []
    property var liveMonitors: []
    property int windowsRevision: 0
    property var lastWindowAction: null          // { kind, address, workspace }

    readonly property var windows: fixedWindows ? fixedWindowList : liveWindows
    readonly property var monitorList: fixedWindows ? fixedMonitorList : liveMonitors
    readonly property var workspaceList: {
        if (!fixedWindows)
            return liveWorkspaces;
        const by = {};
        for (const w of fixedWindowList) {
            const key = String(w.workspace);
            by[key] = by[key] ?? { id: w.workspace, name: w.workspaceName, monitor: w.monitor, windows: [] };
            by[key].windows.push(w.address);
        }
        return Object.values(by).sort((a, b) => (a.id < 0 ? 99 : a.id) - (b.id < 0 ? 99 : b.id));
    }

    function windowAt(address: string): var {
        return windows.find(w => w.address === address) ?? null;
    }

    // One window object in the shape above, from a fixture entry or a `hyprctl clients -j` one.
    function fixtureWindow(w: var, i: int): var {
        const ws = Number(w.workspace);
        return {
            address: String(w.address), appClass: String(w.class ?? ""), title: String(w.title ?? ""),
            workspace: ws, workspaceName: String(w.workspaceName ?? (ws < 0 ? "special" : String(ws))),
            monitor: String(w.monitor ?? ""), x: Number(w.x) || 0, y: Number(w.y) || 0,
            w: Math.max(1, Number(w.w) || 1), h: Math.max(1, Number(w.h) || 1),
            floating: w.floating === true, focused: w.focused === true, focusOrder: w.focused === true ? 0 : i + 1
        };
    }

    function loadWindowsFixture(text: string): void {
        try {
            const d = JSON.parse(text);
            if (!Array.isArray(d?.monitors) || d.monitors.length === 0 || !Array.isArray(d.windows))
                throw new Error("needs monitors and windows");
            fixedMonitorList = d.monitors.map(m => ({ name: String(m.name), w: Number(m.w), h: Number(m.h), x: 0, y: 0, focused: m.focused === true }));
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
    function editFixed(address: string, change: var): void {
        fixedWindowList = fixedWindowList.map(w => w.address === address ? Object.assign({}, w, change) : w);
        windowsRevision++;
    }

    function validAddress(address: string): bool {
        return /^0x[0-9a-f]+$/.test(address);
    }

    function note(kind: string, address: string, ws: int): string {
        lastWindowAction = { kind: kind, address: address, workspace: ws };
        return "ok";
    }

    // Go to the window: its workspace, and the focus. Returns "ok" or "error: …".
    function focusWindow(address: string): string {
        const w = windowAt(address);
        if (!validAddress(address) || !w)
            return `error: unknown window ${address}`;
        if (fixedWindows) {
            let order = 1;
            fixedWindowList = fixedWindowList.map(x => Object.assign({}, x, {
                focused: x.address === address, focusOrder: x.address === address ? 0 : order++
            }));
            windowsRevision++;
        } else {
            dispatchWindow("focus", address, 0);
        }
        return note("focus", address, w.workspace);
    }

    // Move the window to workspace `ws` (1–10) without following it.
    function moveWindow(address: string, ws: int): string {
        const w = windowAt(address);
        if (!validAddress(address) || !w)
            return `error: unknown window ${address}`;
        if (!(Number.isInteger(ws) && ws >= 1 && ws <= 10)) {
            console.warn(`compositor: workspace ${ws} is not 1–10, nothing sent`);
            return `error: workspace ${ws} is not 1–10`;
        }
        if (fixedWindows)
            editFixed(address, { workspace: ws, workspaceName: String(ws) });
        else
            dispatchWindow("move", address, ws);
        return note("move", address, ws);
    }

    function toggleFloating(address: string): string {
        const w = windowAt(address);
        if (!validAddress(address) || !w)
            return `error: unknown window ${address}`;
        if (fixedWindows)
            editFixed(address, { floating: !w.floating });
        else
            dispatchWindow("float", address, 0);
        return note("float", address, w.workspace);
    }

    // Ask the window to close (the app may ask first). Under a fixture it is gone at once.
    function closeWindow(address: string): string {
        const w = windowAt(address);
        if (!validAddress(address) || !w)
            return `error: unknown window ${address}`;
        if (fixedWindows) {
            fixedWindowList = fixedWindowList.filter(x => x.address !== address);
            windowsRevision++;
        } else {
            dispatchWindow("close", address, 0);
        }
        return note("close", address, w.workspace);
    }

    // The real dispatch (frente B): research R8.
    function dispatchWindow(op: string, address: string, ws: int): void {
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

    // Don't call Hyprland.refreshMonitors()/refreshWorkspaces() here: with a Lua config they
    // empty Quickshell's lists instead of refreshing them.
    Component.onCompleted: {
        monitorQuery.running = true;
        activeWindowQuery.running = true;
    }

    // A scale change alone (`hyprctl eval 'hl.monitor(…)'`, as `lab/profile` does) raises no event
    // that reaches onRawEvent, so the scales went stale until the next monitor query. It does change
    // the screen's logical size or pixel ratio: re-read the monitors then.
    Variants {
        model: Quickshell.screens

        QtObject {
            required property var modelData
            readonly property string geometry: `${modelData.width}x${modelData.height}@${modelData.devicePixelRatio}`
            onGeometryChanged: scaleQuery.restart()
        }
    }
    Timer {
        id: scaleQuery
        interval: 100
        onTriggered: monitorQuery.running = true
    }

    // Quickshell updates its objects while handling the event, so bump after it.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            Qt.callLater(root.bump);
            if (event.name.startsWith("monitor") || event.name.startsWith("focusedmon") || event.name === "configreloaded")
                monitorQuery.running = true;
        }
    }
}
