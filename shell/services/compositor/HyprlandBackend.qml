pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The Hyprland backend of the compositor adapter (specs/007-menu-de-pausa/contracts/compositor.md
// §5): the ONLY file that imports Quickshell.Hyprland. Compositor.qml (the facade) loads it when
// the session is Hyprland's and owns everything that doesn't depend on the compositor (fixtures,
// validation, the bar's workspace rule, revisions). This file only reads the live state and acts.
//
// Monitors come from `hyprctl monitors -j`: Quickshell's Hyprland.monitors stays empty on Hyprland
// 0.56 with a Lua config, and its refresh*() calls empty the lists instead of refreshing them, so
// they are never called here.
Item {
    id: root

    readonly property string name: "hyprland"
    readonly property var capabilities: ({
        workspaceModel: "numbered",
        canFloat: true,
        canMoveToWorkspace: true,
        actsOnAnyWindow: true,
        hasGeometry: "rect",
        fullscreenKnown: true
    })

    // [Monitor] { name, x, y, w, h (logical), scale, focused }; replaced on every successful read.
    property var monitors: []
    // [Workspace] { key, index, label, monitor, focused, exists, windows }; the windows come with
    // the window list (frente B, T030).
    readonly property var workspaces: Hyprland.workspaces.values.map(ws => ({
        key: String(ws.id),
        index: ws.id,
        label: String(ws.name ?? ws.id),
        monitor: ws.monitor?.name ?? "",
        focused: ws.id === Hyprland.focusedWorkspace?.id,
        exists: true,
        windows: []
    }))
    // [Window]: the real list is frente B's (T030); empty until then.
    property var windows: []
    readonly property string activeTitle: Hyprland.activeToplevel?.title ?? startupTitle
    readonly property bool fullscreen: false

    signal changed()

    // The index of the workspace shown on `monitorName` (0 = none known). Hyprland.monitors is
    // empty with a Lua config, so this is usually the focused workspace.
    function activeIndexOn(monitorName: string): int {
        const mon = Hyprland.monitors.values.find(m => m.name === monitorName);
        return (mon ? mon.activeWorkspace?.id : Hyprland.focusedWorkspace?.id) ?? 0;
    }

    function refresh(what: string): void {
        if (what === "monitors" || what === "all")
            monitorQuery.running = true;
        if (what === "all")
            activeWindowQuery.running = true;
    }

    function focusWorkspace(key: string): void {
        const id = Number(key);
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        if (ws)
            ws.activate();
        else if (Hyprland.usingLua)     // a Lua config takes a Lua dispatcher expression
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        else
            Hyprland.dispatch(`workspace ${id}`);
    }

    // The window actions (research R8) are frente B's (T031): the facade has validated `id` (and
    // the workspace) before calling.
    function focusWindow(id: string): void {
    }
    function moveWindow(id: string, key: string): void {
    }
    function toggleFloating(id: string): void {
    }
    function closeWindow(id: string): void {
    }

    function validId(id: string): bool {
        return /^0x[0-9a-f]+$/.test(id);
    }

    Process {
        id: monitorQuery
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.monitors = JSON.parse(text).map(m => ({
                        name: String(m.name),
                        x: Number(m.x) || 0,
                        y: Number(m.y) || 0,
                        w: Math.round(m.width / (m.scale || 1)),
                        h: Math.round(m.height / (m.scale || 1)),
                        scale: m.scale,
                        focused: m.focused === true
                    }));
                } catch (e) {
                    // keep the last known monitors
                }
            }
        }
    }

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

    Component.onCompleted: refresh("all")

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

    // Quickshell updates its objects while handling the event, so signal after it.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            Qt.callLater(root.changed);
            if (event.name.startsWith("monitor") || event.name.startsWith("focusedmon") || event.name === "configreloaded")
                monitorQuery.running = true;
        }
    }
}
