pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

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

    readonly property string activeTitle: Fixtures.has("activeWindow")
        ? String(Fixtures.get("activeWindow") ?? "")
        : (Hyprland.activeToplevel?.title ?? "")

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

    // Quickshell updates its objects while handling the event, so bump after it.
    Connections {
        target: Hyprland
        function onRawEvent(event) { Qt.callLater(root.bump); }
    }
}
