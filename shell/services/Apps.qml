pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../strings"
import "appsearch.js" as AppSearch

// The apps of the pause menu's APPS tab (spec 007, contracts/services.md): every app, the pinned
// ones and how many times each was opened. One app (data-model "App"):
//   { id ("kitty.desktop"), name, genericName, description, category (System, Network, Media,
//     Office, Development, Graphics, Game, Other), icon (a path or URL, "" = none), categoryIcon,
//     command (argv), keywords, terminal, workingDirectory, windowClass, actions: [{ name,
//     command }], pinned, uses }
// Real apps (US5, research R4): the freedesktop entries Quickshell watches (DesktopEntries), one
// per id; pins and uses are user state in $XDG_STATE_HOME/rien-os/apps.json (research R11),
// written at once on every pin and every use, never in ~/.config.
// Fixture "apps": the path of a file (pause-fixtures.schema.json, appsFile); its pins and uses
// live in memory and nothing is written.
Singleton {
    id: root

    readonly property bool fixed: Fixtures.has("apps")
    readonly property string fixturePath: fixed ? Fixtures.resolve(String(Fixtures.get("apps") ?? "")) : ""
    readonly property var categoryNames: ["System", "Network", "Media", "Office", "Development", "Graphics", "Game", "Other"]
    readonly property var categoryFiles: ({
        System: "system", Network: "network", Media: "media", Office: "office",
        Development: "dev", Graphics: "graphics", Game: "game", Other: "other"
    })

    property var fixtureApps: []                 // the fixture's apps, as read
    property var liveApps: []                    // the real ones (frente A)
    property string fixtureError: ""
    property bool fixtureReady: false
    property bool liveReady: false

    // The state: pinned ids in the order they were pinned, and uses per id.
    property var pinnedIds: []
    property var uses: ({})
    property var lastLaunch: null                // { id, action, workspace, command, ok, reason }

    readonly property var source: fixed ? fixtureApps : liveApps
    readonly property var apps: source.map(a => Object.assign({}, a, {
        pinned: pinnedIds.includes(a.id),
        uses: Number(uses[a.id] ?? 0)
    }))
    readonly property bool ready: fixed ? fixtureReady : liveReady
    readonly property string error: fixed && fixtureError !== "" ? Strings.pause.appsError : ""
    readonly property int count: apps.length

    function byId(id: string): var {
        return apps.find(a => a.id === id) ?? null;
    }

    // The app a window belongs to: its class against each app's windowClass (case aside).
    function byClass(cls: string): var {
        const c = String(cls ?? "").toLowerCase();
        return c === "" ? null : (apps.find(a => a.windowClass.toLowerCase() === c) ?? null);
    }

    // The app's open windows, the most recently focused first.
    function windowsOf(id: string): var {
        const a = byId(id);
        if (!a)
            return [];
        const c = a.windowClass.toLowerCase();
        return Compositor.windows.filter(w => w.appClass.toLowerCase() === c).sort((p, q) => p.focusOrder - q.focusOrder);
    }

    function sortKey(name: string): string {
        return String(name ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
    }

    function byName(a: var, b: var): int {
        const x = sortKey(a.name), y = sortKey(b.name);
        return x < y ? -1 : x > y ? 1 : 0;
    }

    // The list without a search (data-model "App"): PINNED in pin order, then ALL APPS in `order`
    // ("az", or "used": most used first, then A–Z). An empty group is left out. Items are
    // { label, trailing (open windows, or ""), id }.
    function listed(order: string): var {
        const out = [];
        const item = a => {
            const n = windowsOf(a.id).length;
            return { label: a.name, trailing: n > 0 ? String(n) : "", id: a.id };
        };
        const pins = pinnedIds.map(id => byId(id)).filter(a => a !== null);
        if (pins.length > 0) {
            out.push({ group: Strings.pause.pinned });
            for (const a of pins)
                out.push(item(a));
        }
        const rest = apps.filter(a => !a.pinned).sort((a, b) => order === "used" ? (b.uses - a.uses) || byName(a, b) : byName(a, b));
        if (rest.length > 0) {
            out.push({ group: Strings.pause.allApps });
            for (const a of rest)
                out.push(item(a));
        }
        return out;
    }

    // The ids that match `query`, best first (research R5, appsearch.js).
    function search(query: string): var {
        return AppSearch.rank(apps, query).map(a => a.id);
    }

    // An argv without the .desktop field codes (%f %U %i …; "%%" is a "%"); an argument that was
    // only codes goes away (research R4).
    function cleanArgv(argv: var): var {
        const out = [];
        for (const arg of argv ?? []) {
            const a = String(arg);
            const clean = a.replace(/%([fFuUdDnNickvm%])/g, (m, c) => c === "%" ? "%" : "");
            if (clean !== "" || a === "")
                out.push(clean);
        }
        return out;
    }

    // Open app `id` (action -1 = the app itself, else its action's index) on workspace `ws` (0 =
    // where the user is, else 1–10: the user is taken there first). Never through a shell: the
    // executable is looked up first by a fixed script that gets the name as an argument, then the
    // argv runs detached (research R4, FR-012). Returns "ok" once the launch is on its way
    // (lastLaunch says how it ended) or "error: …". A use is counted only when it really opened.
    function launch(id: string, action: int, ws: int): string {
        const a = byId(id);
        if (!a)
            return `error: unknown app ${id}`;
        const act = action >= 0 ? (a.actions[action] ?? null) : null;
        if (action >= 0 && !act)
            return `error: ${id} has no action ${action}`;
        const argv = cleanArgv(act ? act.command : a.command);
        const where = Math.max(0, Math.min(10, Math.floor(Number(ws) || 0)));
        const command = a.terminal ? Settings.terminal.concat(["-e"], argv) : argv;
        const job = { id: id, action: action, workspace: where, command: command, dir: a.workingDirectory,
                      check: a.terminal ? [Settings.terminal[0], argv[0]] : [argv[0]] };
        if (argv.length === 0 || argv[0] === "") {
            failLaunch(job, "empty command");
            return "error: empty command";
        }
        lastLaunch = { id: id, action: action, workspace: where, command: command, ok: false, reason: "checking" };
        launchQueue = launchQueue.concat([job]);
        checkNext();
        return "ok";
    }

    property var launchQueue: []

    function checkNext(): void {
        if (checker.running || launchQueue.length === 0)
            return;
        checker.job = launchQueue[0];
        launchQueue = launchQueue.slice(1);
        checker.running = true;
    }

    function checked(job: var, code: int, missing: string): void {
        if (code !== 0) {
            failLaunch(job, `${missing || job.check[0]} not found`);
        } else {
            if (job.workspace > 0)
                Compositor.focus(job.workspace);
            const ctx = { command: job.command };
            if (job.dir)
                ctx.workingDirectory = job.dir;
            Quickshell.execDetached(ctx);
            countUse(job.id);
            lastLaunch = { id: job.id, action: job.action, workspace: job.workspace, command: job.command, ok: true, reason: "" };
            console.info(`apps: opened ${job.id}: ${job.command.join(" ")}${job.workspace > 0 ? ` on workspace ${job.workspace}` : ""}`);
        }
        Qt.callLater(root.checkNext);
    }

    function failLaunch(job: var, reason: string): void {
        console.warn(`apps: cannot open ${job.id}: ${reason}`);
        lastLaunch = { id: job.id, action: job.action, workspace: job.workspace, command: job.command, ok: false, reason: reason };
    }

    function countUse(id: string): void {
        const u = Object.assign({}, uses);
        u[id] = Number(u[id] ?? 0) + 1;
        uses = u;
        stateChanged();
    }

    function setPinned(id: string, on: bool): void {
        if (!byId(id) || pinnedIds.includes(id) === on)
            return;
        pinnedIds = on ? pinnedIds.concat([id]) : pinnedIds.filter(x => x !== id);
        stateChanged();
    }

    // Pins or uses changed: saved with the real apps; with the fixture, memory only.
    function stateChanged(): void {
        if (!fixed)
            Qt.callLater(root.saveState);
    }

    // --- the real apps (US5, research R4) ------------------------------------------------------------
    // freedesktop main categories → the project's eight (the first one known wins).
    readonly property var categoryMap: ({
        AudioVideo: "Media", Audio: "Media", Video: "Media", Development: "Development",
        Education: "Office", Game: "Game", Graphics: "Graphics", Network: "Network", Office: "Office",
        Settings: "System", System: "System", Science: "Other", Utility: "Other"
    })

    function categoryOf(categories: var): string {
        for (const c of categories ?? []) {
            const m = categoryMap[String(c)];
            if (m)
                return m;
        }
        return "Other";
    }

    // A theme icon name becomes the theme's file ("" when the theme has none); a path stays.
    function iconOf(icon: string): string {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, true) ?? "";
    }

    function fromEntry(e: var, id: string, command: var): var {
        const category = categoryOf(e.categories);
        return {
            id: id,
            name: String(e.name || id.replace(/\.desktop$/, "")),
            genericName: String(e.genericName ?? ""),
            description: String(e.comment ?? "") || String(e.genericName ?? ""),
            category: category,
            icon: iconOf(String(e.icon ?? "")),
            categoryIcon: categoryIconOf(category),
            command: command,
            keywords: (e.keywords ?? []).map(String),
            terminal: e.runInTerminal === true,
            workingDirectory: String(e.workingDirectory ?? ""),
            windowClass: String(e.startupClass || id.replace(/\.desktop$/, "")),
            actions: (e.actions ?? []).map(a => ({ name: String(a.name), command: cleanArgv(a.command) }))
                .filter(a => a.command.length > 0 && a.command[0] !== "")
        };
    }

    // The list again (at the start and on every change Quickshell sees in the entry folders).
    // Hidden entries are left out; a repeated id keeps its first entry (the user's wins); an
    // entry without a command is left out with a line in the log.
    function readLive(): void {
        if (fixed)
            return;
        const seen = new Set();
        const list = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay)
                continue;
            const raw = String(e.id ?? "");
            const id = raw.endsWith(".desktop") ? raw : raw + ".desktop";
            if (raw === "" || seen.has(id))
                continue;
            seen.add(id);
            const command = cleanArgv(e.command);
            if (command.length === 0 || command[0] === "") {
                console.info(`apps: ${id} has no command, left out`);
                continue;
            }
            list.push(fromEntry(e, id, command));
        }
        liveApps = list;
        liveReady = true;
    }

    Connections {
        target: DesktopEntries
        enabled: !root.fixed
        function onApplicationsChanged(): void {
            root.readLive();
        }
    }

    // --- the state file (research R11) ---------------------------------------------------------------
    readonly property string statePath: {
        const xdg = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state");
        return xdg + "/rien-os/apps.json";
    }

    // Missing: start empty. Unreadable: start empty, with a line in the log. Ids of apps that are
    // gone stay (the app may come back) and are only left out of the list.
    function loadState(): void {
        const text = stateFile.text();
        let d = null;
        if (text) {
            try {
                d = JSON.parse(text);
            } catch (e) {
                d = null;
            }
            if (!d || typeof d !== "object" || Array.isArray(d)) {
                console.info(`apps: ${statePath} is not a valid state file, starting empty`);
                d = null;
            }
        }
        pinnedIds = Array.isArray(d?.pinned) ? d.pinned.filter(x => typeof x === "string") : [];
        const u = {};
        if (d?.uses && typeof d.uses === "object")
            for (const k of Object.keys(d.uses))
                if (Number(d.uses[k]) > 0)
                    u[k] = Math.floor(Number(d.uses[k]));
        uses = u;
    }

    function saveState(): void {
        if (fixed)
            return;
        stateFile.setText(JSON.stringify({ version: 1, pinned: pinnedIds, uses: uses }, null, 2) + "\n");
    }

    // Read once, blocking, before the first list; setText() writes atomically and creates the
    // folder when needed.
    FileView {
        id: stateFile
        path: root.fixed ? "" : root.statePath
        blockLoading: true
        printErrors: false
        atomicWrites: true
    }

    function startLive(): void {
        if (fixed)
            return;
        loadState();
        readLive();          // touching the entries also starts Quickshell's scan
    }

    Component.onCompleted: startLive()

    // The executable lookup: a fixed script, the names as its arguments (never interpreted).
    Process {
        id: checker
        property var job: null
        command: ["sh", "-c", 'for c do command -v -- "$c" >/dev/null 2>&1 || { printf %s "$c"; exit 1; }; done', "sh"].concat(job?.check ?? [])
        stdout: StdioCollector {
            id: checkerOut
        }
        onExited: (code, status) => root.checked(checker.job, code, checkerOut.text.trim())
    }

    // --- the fixture ---------------------------------------------------------------------------------
    function categoryIconOf(category: string): string {
        return Quickshell.shellPath(`assets/icons/category-${categoryFiles[category] ?? "other"}.svg`);
    }

    function fromFixture(a: var): var {
        const category = categoryNames.includes(a.category) ? a.category : "Other";
        return {
            id: String(a.id),
            name: String(a.name),
            genericName: String(a.genericName ?? ""),
            description: String(a.description ?? "") || String(a.genericName ?? ""),
            category: category,
            icon: a.icon ? Fixtures.resolve(String(a.icon)) : "",
            categoryIcon: categoryIconOf(category),
            command: (a.command ?? []).map(String),
            keywords: (a.keywords ?? []).map(String),
            terminal: a.terminal === true,
            workingDirectory: "",
            windowClass: String(a.windowClass ?? String(a.id).replace(/\.desktop$/, "")),
            actions: (a.actions ?? []).map(x => ({ name: String(x.name), command: (x.command ?? []).map(String) }))
        };
    }

    function loadFixture(text: string): void {
        try {
            const d = JSON.parse(text);
            if (!Array.isArray(d?.apps))
                throw new Error("needs an apps list");
            const seen = new Set();
            const list = [];
            for (const a of d.apps) {
                if (typeof a?.id !== "string" || typeof a.name !== "string" || !Array.isArray(a.command) || a.command.length === 0)
                    throw new Error(`bad app ${JSON.stringify(a?.id ?? null)}`);
                if (seen.has(a.id))
                    continue;
                seen.add(a.id);
                list.push(a);
            }
            fixtureApps = list.map(a => fromFixture(a));
            pinnedIds = list.filter(a => a.pinned === true).map(a => a.id);
            const u = {};
            for (const a of list)
                u[a.id] = Math.max(0, Number(a.uses) || 0);
            uses = u;
            fixtureError = "";
        } catch (e) {
            failFixture(`${fixturePath}: ${e}`);
        }
        fixtureReady = true;
    }

    function failFixture(reason: string): void {
        console.warn(`apps: fixture unusable, ${reason}`);
        fixtureApps = [];
        pinnedIds = [];
        uses = {};
        fixtureError = reason;
        fixtureReady = true;
    }

    // Back to the fixture file (a fixture loaded again, `pause reset`).
    function resetFixture(): void {
        lastLaunch = null;
        if (fixed)
            fixtureFile.reload();
    }

    FileView {
        id: fixtureFile
        path: root.fixturePath
        printErrors: false
        blockLoading: true
        onLoaded: root.loadFixture(text())
        onLoadFailed: root.failFixture(`cannot read ${path}`)
    }

    onFixedChanged: {
        lastLaunch = null;
        fixtureReady = false;
        startLive();
    }

    Connections {
        target: Fixtures
        function onDataChanged(): void {
            root.resetFixture();
        }
    }
}
