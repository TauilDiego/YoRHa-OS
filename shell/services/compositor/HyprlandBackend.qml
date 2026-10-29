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
    // [Workspace] { key, index, label, monitor, focused, exists, windows: [id] }. The list and the
    // focus come from Quickshell's Hyprland.workspaces (live, what the bar has always read); the
    // monitor (empty there with a Lua config) and the windows come from the last reads of
    // `hyprctl workspaces -j` and `clients -j`.
    readonly property var workspaces: Hyprland.workspaces.values.map(ws => ({
        key: String(ws.id),
        index: ws.id,
        label: String(ws.name ?? ws.id),
        monitor: ws.monitor?.name || (workspaceMonitors[String(ws.id)] ?? ""),
        focused: ws.id === Hyprland.focusedWorkspace?.id,
        exists: true,
        windows: windows.filter(w => w.workspaceKey === String(ws.id)).map(w => w.id)
    }))
    // [Window] (contracts/compositor.md §2, plus the facade's flat fields), from `hyprctl clients
    // -j` (research R7): re-read at start and on the window and workspace events, a burst of
    // events folded into one read by a 50 ms timer. Replaced only when something changed; a read
    // that fails keeps the last list and says so in the log.
    property var windows: []
    // { workspace id: monitor name }, from `hyprctl workspaces -j`.
    property var workspaceMonitors: ({})
    // { monitor id: name }, from `hyprctl monitors -j` (a client names its monitor by id).
    property var monitorNames: ({})
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
        if (what === "windows" || what === "all")
            windowsTimer.restart();
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

    // The window actions (research R8, names confirmed by the T003 spike on Hyprland 0.56.2). The
    // facade has validated `id` and the workspace already; they are checked again here, because
    // they go into a dispatcher expression: an id that isn't ^0x[0-9a-f]+$ or a workspace that
    // isn't a whole 1–10 sends nothing and says so in the log. A Lua config takes hl.dsp.*
    // expressions; an old (hyprlang) config, the classic dispatchers.
    function focusWindow(id: string): void {
        if (!checked(id, "focus"))
            return;
        if (Hyprland.usingLua)          // goes to the window's workspace too (T003)
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:${id}" })`);
        else
            Hyprland.dispatch(`focuswindow address:${id}`);
    }
    // To workspace `key` (a number 1–10) without following it: the monitor stays where it is.
    function moveWindow(id: string, key: string): void {
        if (!checked(id, "move"))
            return;
        const ws = Number(key);
        if (!/^[0-9]+$/.test(String(key)) || !Number.isInteger(ws) || ws < 1 || ws > 10) {
            console.warn(`compositor: hyprland move ${id} to workspace "${key}": not a whole 1–10, nothing sent`);
            return;
        }
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${ws}, follow = false, window = "address:${id}" })`);
        else
            Hyprland.dispatch(`movetoworkspacesilent ${ws},address:${id}`);
    }
    function toggleFloating(id: string): void {
        if (!checked(id, "float"))
            return;
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.window.float({ action = "toggle", window = "address:${id}" })`);
        else
            Hyprland.dispatch(`togglefloating address:${id}`);
    }
    // The polite close (the app may ask first), never a kill.
    function closeWindow(id: string): void {
        if (!checked(id, "close"))
            return;
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${id}" })`);
        else
            Hyprland.dispatch(`closewindow address:${id}`);
    }

    function checked(id: string, op: string): bool {
        if (validId(id))
            return true;
        console.warn(`compositor: hyprland ${op} on window "${id}": not an address (^0x[0-9a-f]+$), nothing sent`);
        return false;
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
                    const list = JSON.parse(text);
                    const names = {};
                    for (const m of list)
                        names[String(m.id)] = String(m.name);
                    root.monitorNames = names;
                    root.monitors = list.map(m => ({
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
            if (root.windowEvents.includes(event.name))
                windowsTimer.restart();
        }
    }

    // --- the windows (spec 007 frente B, T030; research R7) -----------------------------------------
    // The raw events after which the windows or workspaces may have changed. A monitor event also
    // re-reads them (a window's monitor, the workspaces' owner).
    readonly property var windowEvents: [
        "openwindow", "closewindow", "movewindow", "movewindowv2", "windowtitle", "windowtitlev2",
        "changefloatingmode", "workspace", "workspacev2", "createworkspace", "createworkspacev2",
        "destroyworkspace", "destroyworkspacev2", "moveworkspace", "moveworkspacev2",
        "renameworkspace", "activewindowv2", "fullscreen", "activespecial", "activespecialv2",
        "monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2", "configreloaded"
    ]

    Timer {
        id: windowsTimer
        interval: 50
        onTriggered: {
            // A read still running when a new burst ends: read again once it is done.
            if (clientsQuery.running || workspacesQuery.running) {
                root.readAgain = true;
                return;
            }
            clientsQuery.running = true;
            workspacesQuery.running = true;
        }
    }
    property bool readAgain: false

    // One window from `hyprctl clients -j`: rect relative to its monitor, in logical px.
    function windowOf(c: var): var {
        const mon = String(monitorNames[String(c.monitor)] ?? "");
        const m = monitors.find(x => x.name === mon);
        const wsId = Number(c.workspace?.id ?? 0);
        const wsName = String(c.workspace?.name ?? wsId);
        const special = wsId < 0 || wsName.startsWith("special");
        const at = Array.isArray(c.at) ? c.at : [0, 0];
        const size = Array.isArray(c.size) ? c.size : [1, 1];
        const rect = {
            x: Math.round(Number(at[0]) - (m?.x ?? 0)),
            y: Math.round(Number(at[1]) - (m?.y ?? 0)),
            w: Math.max(1, Math.round(Number(size[0]) || 1)),
            h: Math.max(1, Math.round(Number(size[1]) || 1))
        };
        const order = Number(c.focusHistoryID);
        const id = String(c.address ?? "");
        return {
            id: id, address: id, appClass: String(c.class ?? ""), title: String(c.title ?? ""),
            workspaceKey: String(wsId), workspace: special ? -1 : wsId, workspaceName: wsName,
            monitor: mon, floating: c.floating === true, focused: order === 0,
            focusOrder: Number.isInteger(order) && order >= 0 ? order : 999, fullscreen: Number(c.fullscreen) > 0,
            rect: rect, column: null, x: rect.x, y: rect.y, w: rect.w, h: rect.h
        };
    }

    Process {
        id: clientsQuery
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list;
                try {
                    list = JSON.parse(text);
                    if (!Array.isArray(list))
                        throw new Error("not a list");
                } catch (e) {
                    console.warn(`compositor: hyprctl clients -j unreadable (${e}), keeping the last ${root.windows.length} windows`);
                    return;
                }
                const next = list.filter(c => c && c.mapped !== false && root.validId(String(c.address ?? "")))
                    .map(c => root.windowOf(c));
                if (JSON.stringify(next) !== JSON.stringify(root.windows)) {
                    root.windows = next;
                    root.changed();
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0)
                console.warn(`compositor: hyprctl clients -j exited with ${code}, keeping the last windows`);
            if (root.readAgain && !workspacesQuery.running) {
                root.readAgain = false;
                windowsTimer.restart();
            }
        }
    }

    Process {
        id: workspacesQuery
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const out = {};
                    for (const ws of JSON.parse(text))
                        out[String(ws.id)] = String(ws.monitor ?? "");
                    if (JSON.stringify(out) !== JSON.stringify(root.workspaceMonitors))
                        root.workspaceMonitors = out;
                } catch (e) {
                    console.warn(`compositor: hyprctl workspaces -j unreadable (${e}), keeping the last workspaces`);
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0)
                console.warn(`compositor: hyprctl workspaces -j exited with ${code}, keeping the last workspaces`);
            if (root.readAgain && !clientsQuery.running) {
                root.readAgain = false;
                windowsTimer.restart();
            }
        }
    }
    // The windows' monitors and rects depend on the monitors: read them again when those change.
    onMonitorsChanged: windowsTimer.restart()
}
