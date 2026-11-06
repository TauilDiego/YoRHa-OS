pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
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
        fullscreenKnown: true,
        keyboardLayouts: true,      // spec 013 (front C)
        // spec 019 (contracts/compositor-adapter.md)
        keyboardOptions: true,
        monitorInfo: true,
        shortcutsList: true,
        configFile: true
    })

    // [Monitor] { name, x, y, w, h (logical), width, height (physical px), refreshRate (Hz), scale,
    // focused }; replaced on every successful read.
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
    // Quickshell keeps the last active toplevel after its window closes or the focus moves to an
    // empty workspace, so the title would stay on the bar (audit D-08). Nothing in focus (the
    // activewindowv2 event with no address) or a focused workspace with no windows = no title.
    readonly property string activeTitle: nothingFocused || focusedWorkspaceEmpty ? "" : (Hyprland.activeToplevel?.title ?? startupTitle)
    property bool nothingFocused: false
    property bool windowsRead: false            // the first `clients -j` read came back
    readonly property bool focusedWorkspaceEmpty: {
        const ws = workspaces.find(w => w.focused);
        return windowsRead && ws !== undefined && ws.windows.length === 0;
    }
    // spec 008 (R11): is the window in focus full screen? From `hyprctl activewindow -j` (field
    // `fullscreen`, a mode: 0 none, 1 maximized, 2 full screen, 3 both; only the full-screen bit
    // counts), re-read on the fullscreen, active window and workspace events.
    property bool fullscreen: false

    signal changed()
    // U13 (audit D-04/D-05): a key bound to `global, yorha:<name>` (hyprland_global_shortcuts_v1)
    // reaches the shell over Wayland, without starting a process; the facade passes it on.
    signal shortcut(string name)

    GlobalShortcut {
        appid: "yorha"
        name: "pause"
        description: "Open or close the pause menu"
        onPressed: root.shortcut("pause")
    }
    GlobalShortcut {
        appid: "yorha"
        name: "settings"
        description: "Open or close the settings (SYSTEM)"
        onPressed: root.shortcut("settings")
    }

    // U13 (audit D-04): the keys typed while the menu opens. The menu key also puts Hyprland in the
    // submap "yorha-menu" (yorha-shell.lua), where these keys are bound to `global, yorha:key-<k>` and
    // every other key is swallowed, so nothing reaches the window under the menu before the menu has
    // the keyboard. The shell hands them to the menu and ends the submap once it has the keyboard
    // (endKeyCapture); the submap also ends by itself after 1.5 s.
    readonly property var menuKeys: {
        const out = [];
        for (const c of "abcdefghijklmnopqrstuvwxyz") {
            out.push(c);
            out.push("shift-" + c);
        }
        for (const c of "0123456789")
            out.push(c);
        return out.concat(["space", "minus", "period", "Return", "KP_Enter", "BackSpace", "Tab", "Escape", "Up", "Down"]);
    }
    signal menuKey(string name)
    Instantiator {
        model: root.menuKeys
        delegate: GlobalShortcut {
            required property string modelData
            appid: "yorha"
            name: "key-" + modelData
            description: "A key typed while the menu opens"
            onPressed: root.menuKey(modelData)
        }
    }
    property string submap: ""                  // the submap Hyprland is in (the "submap" event)
    function endKeyCapture(): void {
        if (submap !== "yorha-menu")
            return;
        submap = "";
        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.submap("reset")`);
        else
            Hyprland.dispatch("submap reset");
    }

    // The index of the workspace shown on `monitorName` (0 = none known). Hyprland.monitors is
    // empty with a Lua config, so this is usually the focused workspace.
    function activeIndexOn(monitorName: string): int {
        const mon = Hyprland.monitors.values.find(m => m.name === monitorName);
        return (mon ? mon.activeWorkspace?.id : Hyprland.focusedWorkspace?.id) ?? 0;
    }

    function refresh(what: string): void {
        if (what === "monitors" || what === "all")
            readMonitors();
        if (what === "windows" || what === "all")
            windowsTimer.restart();
        if (what === "fullscreen" || what === "all")
            refreshFullscreen();
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

    // spec 019 (sondagem.md): nothing is asked in the wait after a reload; afterReload reads them at its
    // end, so a read skipped here isn't lost. The windows' read, the same (windowsTimer).
    function readMonitors(): void {
        if (!afterReload.running)
            monitorQuery.running = true;
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
                        width: Number(m.width) || 0,
                        height: Number(m.height) || 0,
                        refreshRate: Number(m.refreshRate) || 0,
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
                root.nothingFocused = root.startupTitle === "" && Hyprland.activeToplevel === null;
            }
        }
    }

    // --- spec 008: the full-screen window in focus (R11) -------------------------------------------
    Process {
        id: fullscreenQuery
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const fs = JSON.parse(text).fullscreen;
                    root.fullscreen = fs === true || (Number(fs) & 2) !== 0;
                } catch (e) {
                    root.fullscreen = false;      // no window in focus
                }
            }
        }
    }
    function refreshFullscreen(): void {
        if (fullscreenQuery.running)
            fullscreenAgain.restart();
        else
            fullscreenQuery.running = true;
    }
    Timer {
        id: fullscreenAgain
        interval: 50
        onTriggered: root.refreshFullscreen()
    }
    // --- end spec 008 --------------------------------------------------------------------------------

    // --- spec 013, front C: the keyboard layouts (research R6) ---------------------------------------
    // `keyboardLayouts` is what the compositor has now (`input:kb_layout`, split at commas). A Lua config
    // (0.56) takes `hyprctl eval 'hl.config({ input = { kb_layout = "us,br" } })'`, live for every
    // keyboard; `hyprctl keyword` refuses ("Use eval"), so it is only the way for an old (hyprlang)
    // config. A `hyprctl reload` puts the file's layout back, so the backend reads it again after a
    // reload and sets the wanted ones back. The layout is also in the managed config, with the shortcut that
    // switches (`hyprctl switchxkblayout all next`); writing it there is the installer's job.
    property var keyboardLayouts: []
    property string wantedLayouts: ""
    property bool setAgain: false

    // Only XKB layout names go into the command (a-z, 2–8 letters), whoever calls.
    function setKeyboardLayouts(list: var): string {
        if (!Array.isArray(list) || list.length === 0 || !list.every(x => /^[a-z]{2,8}$/.test(String(x))))
            return "error: not a list of layout names";
        wantedLayouts = list.join(",");
        if (layoutSet.running) {
            setAgain = true;
            return "ok";
        }
        layoutSet.command = Hyprland.usingLua
            ? ["hyprctl", "eval", `hl.config({ input = { kb_layout = "${wantedLayouts}" } })`]
            : ["hyprctl", "keyword", "input:kb_layout", wantedLayouts];
        layoutSet.running = true;
        return "ok";
    }
    function refreshKeyboardLayouts(): void {
        if (!layoutQuery.running)
            layoutQuery.running = true;
    }

    Process {
        id: layoutSet
        stdout: StdioCollector {
            id: setOut
        }
        onExited: code => {
            if (code !== 0 || !setOut.text.startsWith("ok"))
                console.warn(`compositor: setting the keyboard layouts to "${root.wantedLayouts}" failed (${code}): ${setOut.text.trim()}`);
            if (root.setAgain) {
                root.setAgain = false;
                root.setKeyboardLayouts(root.wantedLayouts.split(","));
            } else {
                root.refreshKeyboardLayouts();
            }
        }
    }
    Process {
        id: layoutQuery
        command: ["hyprctl", "getoption", "-j", "input:kb_layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const str = String(JSON.parse(text).str ?? "");
                    root.keyboardLayouts = str === "" || str === "[[EMPTY]]" ? [] : str.split(",");
                    // A reload went back to the file's layout: the wanted ones come back.
                    if (root.wantedLayouts !== "" && str !== root.wantedLayouts && !layoutSet.running)
                        root.setKeyboardLayouts(root.wantedLayouts.split(","));
                } catch (e) {
                    // keep the last known layouts
                }
            }
        }
    }
    // --- end front C ---------------------------------------------------------------------------------

    // --- spec 019: the config file's values (contracts/compositor-adapter.md, research R1) ------------
    // The session's id: the same while the compositor lives, new on a new login (proved, T003 P7).
    readonly property string sessionId: String(Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? "")
    // The last read: { repeatDelay, repeatRate, kbOptions, kbLayout }, null before the first one.
    property var configValues: null
    // Etapa 1C fills these (HyprlandBackend.shortcuts, R2).
    property var shortcuts: []
    property string shortcutModifier: ""
    signal configRead(var values, string trigger, var errors)
    signal configWriteDone(bool ok, string error)

    // One batch request is one read, with no reload in the middle. Asked during a read, a read runs
    // after it, keeping the strongest trigger: a reload's comparison is never lost to a poll.
    readonly property var readRank: ({ poll: 0, start: 1, reload: 2 })
    property string readTrigger: ""
    property string readNext: ""
    function readConfig(trigger: string): void {
        if (configQuery.running || configWait.running) {
            if (readNext === "" || readRank[trigger] > readRank[readNext])
                readNext = trigger;
            return;
        }
        readTrigger = trigger;
        if (trigger === "reload")
            configWait.restart();
        else
            configQuery.running = true;
    }
    // A config with an error raises Hyprland's error overlay. On 0.56.2, a request right after the
    // reload's event can leave its main thread waiting forever on the overlay's text (the lab: 4 hangs
    // in 25 rounds reading at once, none in 25 with this wait; lab/019/prova-trava, sondagem.md).
    // The value read later is still the file's: nothing else sets it in between.
    Timer {
        id: configWait
        interval: 300
        onTriggered: configQuery.running = true
    }
    // "[[EMPTY]]" is how getoption says an empty string (T003 P9).
    function optionText(reply: var): string {
        const s = String(reply?.str ?? "");
        return s === "[[EMPTY]]" ? "" : s;
    }
    // The replies come one after the other: each one is a JSON value, and they are split where one
    // ends. null if any of the five didn't come back whole: a read half done is no read at all.
    function parseConfigReplies(text: string): var {
        const parts = [];
        let rest = text.trim();
        while (rest !== "" && parts.length < 5) {
            const cut = rest.indexOf("\n\n");
            parts.push(cut < 0 ? rest : rest.slice(0, cut));
            rest = cut < 0 ? "" : rest.slice(cut + 2).trim();
        }
        if (parts.length !== 5)
            return null;
        try {
            const r = parts.map(p => JSON.parse(p));
            if (!Number.isInteger(r[0].int) || !Number.isInteger(r[1].int) || typeof r[2].str !== "string"
                    || typeof r[3].str !== "string" || !Array.isArray(r[4]))
                return null;
            return {
                values: { repeatDelay: r[0].int, repeatRate: r[1].int, kbOptions: optionText(r[2]), kbLayout: optionText(r[3]) },
                errors: r[4].map(x => String(x)).filter(x => x.trim() !== "")
            };
        } catch (e) {
            return null;
        }
    }
    Process {
        id: configQuery
        command: ["hyprctl", "--batch", "j/getoption input:repeat_delay ; j/getoption input:repeat_rate ; j/getoption input:kb_options ; j/getoption input:kb_layout ; j/configerrors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const trigger = root.readTrigger;
                const read = root.parseConfigReplies(text);
                if (read) {
                    root.configValues = read.values;
                    root.configRead(read.values, trigger, read.errors);
                } else {
                    console.info(`compositor: the config read (${trigger}) didn't come back whole, nothing compared`);
                }
                // spec 013's reapply, until etapa 1C moves it to FileWins: after the read, so what
                // was just read is the file's value and not this eval's.
                if (trigger === "reload")
                    root.refreshKeyboardLayouts();
            }
        }
        onExited: {
            root.flushWrite();
            if (root.readNext === "")
                return;
            const next = root.readNext;
            root.readNext = "";
            root.readConfig(next);
        }
    }

    // Only the keys of `map`, in one eval. Numbers are checked; texts only with ^[a-z0-9_:,]*$, because
    // they go into the command (as setKeyboardLayouts). The last wanted one wins (research R3).
    readonly property var configKeys: ({ repeatDelay: "repeat_delay", repeatRate: "repeat_rate", kbOptions: "kb_options", kbLayout: "kb_layout" })
    property string writeCode: ""
    property string writeNext: ""
    function setConfigValues(map: var): string {
        const parts = [];
        for (const k of Object.keys(map ?? {})) {
            const name = configKeys[k];
            const v = map[k];
            if (!name)
                return `error: unknown value ${k}`;
            if (k === "repeatDelay" || k === "repeatRate") {
                if (!Number.isInteger(v) || v < 0 || v > 100000)
                    return `error: ${k} is not a whole number`;
                parts.push(`${name} = ${v}`);
            } else {
                if (typeof v !== "string" || !/^[a-z0-9_:,]*$/.test(v))
                    return `error: ${k} has characters that can't go in the command`;
                parts.push(`${name} = "${v}"`);
            }
        }
        if (parts.length === 0)
            return "ok";
        writeNext = `hl.config({ input = { ${parts.join(", ")} } })`;
        flushWrite();
        return "ok";
    }
    // Never during a read that compares: what the read finds has to be the file's value.
    function flushWrite(): void {
        if (writeNext === "" || configSet.running || configWait.running || (configQuery.running && readTrigger !== "poll"))
            return;
        writeCode = writeNext;
        writeNext = "";
        configSet.command = ["hyprctl", "eval", writeCode];
        configSet.running = true;
    }
    Process {
        id: configSet
        stdout: StdioCollector {
            id: configSetOut
        }
        onExited: code => {
            const good = code === 0 && configSetOut.text.startsWith("ok");
            if (!good)
                console.info(`compositor: "${root.writeCode}" failed (${code}): ${configSetOut.text.trim()}`);
            root.configWriteDone(good, good ? "" : configSetOut.text.trim());
            root.readConfig("poll");
            root.flushWrite();
        }
    }
    // --- end spec 019 ---------------------------------------------------------------------------------

    Component.onCompleted: {
        refresh("all");
        refreshKeyboardLayouts();
        readConfig("start");
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
        onTriggered: root.readMonitors()
    }

    // Quickshell updates its objects while handling the event, so signal after it.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            Qt.callLater(root.changed);
            if (event.name === "submap")
                root.submap = String(event.data ?? "");
            if (event.name === "activewindowv2")       // "<address>", or nothing with no window in focus
                root.nothingFocused = String(event.data ?? "").replace(/,/g, "").trim() === "";
            if (event.name.startsWith("monitor") || event.name.startsWith("focusedmon"))
                root.readMonitors();
            if (event.name === "configreloaded") {     // spec 019: nothing asked at once (configWait)
                root.readConfig("reload");             // (R1) the file's values, before any reapply
                afterReload.restart();
            }
            if (root.windowEvents.includes(event.name))
                windowsTimer.restart();
            // spec 008: full screen (R10, R11)
            if (event.name === "fullscreen" || event.name.startsWith("activewindow") || event.name.startsWith("workspace")
                    || event.name === "closewindow")
                root.refreshFullscreen();
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
        "monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2"
    ]
    // The windows and the monitors after a reload, as late as the config's read (configWait).
    Timer {
        id: afterReload
        interval: configWait.interval
        onTriggered: {
            monitorQuery.running = true;
            windowsTimer.restart();
        }
    }

    Timer {
        id: windowsTimer
        interval: 50
        onTriggered: {
            if (afterReload.running)
                return;
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
                root.windowsRead = true;
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
