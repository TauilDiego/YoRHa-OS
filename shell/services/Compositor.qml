pragma Singleton

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

    onFixedWorkspacesChanged: fixedFocus = 0
    onFixedFocusChanged: bump()

    Connections {
        target: Fixtures
        function onDataChanged() {
            root.fixedFocus = 0;
            root.bump();
        }
    }

    // Don't call Hyprland.refreshMonitors()/refreshWorkspaces() here: with a Lua config they
    // empty Quickshell's lists instead of refreshing them.
    Component.onCompleted: {
        monitorQuery.running = true;
        activeWindowQuery.running = true;
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
