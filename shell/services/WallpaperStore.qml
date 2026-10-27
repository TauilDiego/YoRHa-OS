pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../ds"

// What each monitor shows (spec 004, contracts/services.md): the "all monitors" choice, each
// monitor's own choice, the transition and the pictures shown without the paper filter.
// `set` and `step` only change the choice: each Wallpaper watches resolve(its monitor) and plays
// its own transition. The choice is user state, kept in $XDG_STATE_HOME/rien-os/wallpaper.json
// (contracts/state.schema.json), never in the user's config (constitution III). With the
// `wallpaper` fixture everything comes from it and nothing is written.
Singleton {
    id: root

    readonly property bool fixed: Fixtures.has("wallpaper")
    // Transitions are instant with fixtures (identical screenshots) or with reduced motion (FR-016).
    readonly property bool instant: Fixtures.active || Settings.reduceMotion
    readonly property string fallback: "scene:menu"

    property string all: ""
    property var monitors: ({})            // output name → id
    property var picked: ({})              // the transition the user picked last: kind, cell, trail, glitch
    property var paperFilterOff: []        // absolute paths

    // The transition in effect: the last pick > shell.json > defaults.json (research R8).
    readonly property var transition: {
        const p = picked, c = Settings.camouflage;
        return {
            kind: p.kind ?? Settings.wallpaperTransition,
            cell: p.cell ?? c.cell,
            trail: p.trail ?? c.trail,
            glitch: p.glitch ?? c.glitch
        };
    }

    // The id a monitor shows (FR-020): its own choice, else "all", else the default scene. A
    // picture is only known once the catalog has read the folder: until then the answer is "",
    // so nothing flips to the fallback and back at start. A choice that no longer exists falls
    // back, with one line in the log.
    readonly property var warned: ({})
    function resolve(monitorName: string): string {
        for (const id of [monitors[monitorName] ?? "", all]) {
            if (!id)
                continue;
            if (WallpaperCatalog.byId(id)?.available)
                return id;
            if (id.startsWith("image:") && !WallpaperCatalog.ready)
                return "";
            if (!warned[id]) {
                warned[id] = true;
                console.info(`wallpaper: ${id} is gone, ${monitorName} falls back`);
            }
        }
        return fallback;
    }

    // --- spec 004 US6: the bar's tone, per monitor ---------------------------------------------------
    // What each monitor's bar shows now, 0 (paper tone) → 1 (light tone); written by that monitor's
    // Wallpaper, read by its Hud.
    property var toneMix: ({})
    function setToneMix(monitorName: string, value: real): void {
        if (toneMix[monitorName] === value)
            return;
        const m = Object.assign({}, toneMix);
        m[monitorName] = value;
        toneMix = m;
    }
    // The tone a wallpaper asks for (FR-026): 1 light (the dark scene, a dark picture), 0 paper,
    // -1 not known yet (a picture not measured yet).
    function toneOf(id: string): real {
        const w = WallpaperCatalog.byId(id);
        if (!w)
            return -1;
        if (w.type === "scene")
            return w.scene?.kind === "dark" ? 1 : 0;
        if (w.type !== "image")
            return -1;
        const luma = WallpaperCatalog.lumaOf(w.path, !paperFilterOff.includes(w.path));
        return luma < 0 ? -1 : luma < Tokens.hudLightBelow ? 1 : 0;
    }
    // --- end spec 004 US6 --------------------------------------------------------------------------

    function hasScreen(name: string): bool {
        return Quickshell.screens.some(s => s.name === name);
    }

    // Apply `id` on one monitor, or on all of them ("" or "all"), which clears the monitors' own
    // choices. Returns "ok" or "error: …".
    function set(id: string, monitor: string): string {
        const w = WallpaperCatalog.byId(id);
        if (!w)
            return `error: unknown wallpaper ${id}`;
        if (!w.available)
            return `error: ${id} is not available yet`;
        if (monitor === "" || monitor === "all") {
            all = id;
            monitors = ({});
        } else {
            if (!hasScreen(monitor))
                return `error: unknown monitor ${monitor}`;
            const m = Object.assign({}, monitors);
            m[monitor] = id;
            monitors = m;
        }
        changed();
        return "ok";
    }

    // The next (delta 1) or previous (-1) available wallpaper on a monitor ("" = the focused
    // one), wrapping around, in the catalog's order.
    function step(monitor: string, delta: int): string {
        const name = monitor || Compositor.focusedMonitor || (Quickshell.screens[0]?.name ?? "");
        if (!hasScreen(name))
            return `error: unknown monitor ${name}`;
        const list = WallpaperCatalog.items.filter(w => w.available);
        if (list.length === 0)
            return "error: the catalog is empty";
        const i = list.findIndex(w => w.id === resolve(name));
        const from = i >= 0 ? i : (delta > 0 ? -1 : 0);
        return set(list[(from + delta + list.length) % list.length].id, name);
    }

    function setTransition(kind: string): string {
        if (!Settings.transitionKinds.includes(kind))
            return `error: transition must be one of ${Settings.transitionKinds.join(", ")}`;
        picked = Object.assign({}, picked, { kind: kind });
        changed();
        return "ok";
    }

    function setCamouflage(cell: int, trail: int, glitch: int): string {
        const v = { cell: cell, trail: trail, glitch: glitch };
        for (const k in v) {
            const err = Settings.camouflageError(k, v[k]);
            if (err)
                return `error: ${err}`;
        }
        picked = Object.assign({}, picked, v);
        changed();
        return "ok";
    }

    function setPaperFilter(path: string, on: bool): string {
        if (!WallpaperCatalog.byId("image:" + path))
            return `error: no picture ${path} in ${WallpaperCatalog.folder}`;
        const off = paperFilterOff.filter(p => p !== path);
        if (!on)
            off.push(path);
        paperFilterOff = off;
        changed();
        return "ok";
    }

    // Only the keys a state or fixture may set, and only valid values.
    function cleanTransition(t: var): var {
        const out = {};
        if (!t || typeof t !== "object")
            return out;
        if (Settings.transitionKinds.includes(t.kind))
            out.kind = t.kind;
        for (const k of ["cell", "trail", "glitch"])
            if (t[k] !== undefined && !Settings.camouflageError(k, t[k]))
                out[k] = t[k];
        return out;
    }

    function load(src: var): void {
        const d = src && typeof src === "object" ? src : {};
        all = typeof d.all === "string" ? d.all : "";
        monitors = d.monitors && typeof d.monitors === "object" && !Array.isArray(d.monitors) ? Object.assign({}, d.monitors) : ({});
        picked = cleanTransition(d.transition);
        paperFilterOff = Array.isArray(d.paperFilterOff) ? d.paperFilterOff.filter(p => typeof p === "string") : [];
    }

    // Start over from the fixture, or from the saved state.
    function reset(): void {
        load(fixed ? Fixtures.get("wallpaper") : readState());
    }

    // --- the state file (research R8) -------------------------------------------------------------
    readonly property string statePath: {
        const xdg = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state");
        return xdg + "/rien-os/wallpaper.json";
    }

    // Unreadable or missing: start empty (a broken file gets a line in the log).
    function readState(): var {
        const text = stateFile.text();
        if (!text)
            return {};
        try {
            const d = JSON.parse(text);
            if (d && typeof d === "object" && !Array.isArray(d))
                return d;
        } catch (e) {
        }
        if (badState !== text) {                  // once per broken content (reset() runs often)
            badState = text;
            console.info(`wallpaper: ${statePath} is not a valid state file, starting from the defaults`);
        }
        return {};
    }
    property string badState: ""

    // A choice changed: save it a moment later, in one write (never with the fixture).
    function changed(): void {
        if (!fixed)
            saveSoon.restart();
    }

    function save(): void {
        if (fixed)
            return;
        const out = { version: 1 };
        if (all)
            out.all = all;
        out.monitors = monitors;
        if (Object.keys(picked).length > 0)
            out.transition = picked;
        out.paperFilterOff = paperFilterOff;
        stateFile.setText(JSON.stringify(out, null, 2) + "\n");
    }

    Timer {
        id: saveSoon
        interval: 250
        onTriggered: root.save()
    }

    // Read once, blocking, so the first frame already shows the saved choice. setText() writes
    // atomically and creates the folder when needed.
    FileView {
        id: stateFile
        path: root.statePath
        blockLoading: true
        printErrors: false          // no file yet is the normal first run
        atomicWrites: true
    }

    Component.onCompleted: reset()
    Connections {
        target: Fixtures
        function onDataChanged(): void {
            root.reset();
        }
    }
}
