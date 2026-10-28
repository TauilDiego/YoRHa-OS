pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../strings"

// The apps of the pause menu's APPS tab (spec 007, contracts/services.md): every app, the pinned
// ones and how many times each was opened. One app (data-model "App"):
//   { id ("kitty.desktop"), name, genericName, description, category (System, Network, Media,
//     Office, Development, Graphics, Game, Other), icon (a path or URL, "" = none), categoryIcon,
//     command (argv), keywords, terminal, workingDirectory, windowClass, actions: [{ name,
//     command }], pinned, uses }
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

    // The ids that match `query`, best first (research R5; frente A).
    function search(query: string): var {
        return [];
    }

    // Open app `id` (action -1 = the app itself, else its action's index) on workspace `ws` (0 =
    // where the user is, else 1–10). Returns "ok" or "error: …" (frente A).
    function launch(id: string, action: int, ws: int): string {
        const a = byId(id);
        if (!a)
            return `error: unknown app ${id}`;
        lastLaunch = { id: id, action: action, workspace: ws, command: a.command, ok: false, reason: "not wired yet" };
        return "ok";
    }

    function setPinned(id: string, on: bool): void {
        if (!byId(id) || pinnedIds.includes(id) === on)
            return;
        pinnedIds = on ? pinnedIds.concat([id]) : pinnedIds.filter(x => x !== id);
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
    }

    Connections {
        target: Fixtures
        function onDataChanged(): void {
            root.resetFixture();
        }
    }
}
