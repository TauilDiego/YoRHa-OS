pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../ds"
import "../strings"

// The settings pop-up's data (spec 003, contracts/services.md): categories and options read
// from shell/fixtures/settings-default.json, or from the file named by the active fixture's
// "settings" domain. Values live in memory for the session: closing and reopening keeps them,
// restarting the shell goes back to the file. Nothing is written and nothing touches the
// system (FR-018).
// Values: toggle → bool, choice → index in `values`, slider → 0–100; actions and infos have none.
// 004 acabamento: a choice with `"setting": key` is live. Its value is the shell setting's level
// (Settings.levelOf), and changing it changes the setting for the session (Settings.setSession).
// Still nothing is written.
// Options are addressed by category id + option id; "cat.opt" keys the maps below.
Singleton {
    id: root

    readonly property string defaultCatalog: "fixtures/settings-default.json"
    readonly property string catalogPath: Fixtures.has("settings")
        ? Fixtures.resolve(String(Fixtures.get("settings") ?? ""))
        : Fixtures.resolve(defaultCatalog)

    property var categories: []
    property string error: ""                    // the card's message when the catalog is unusable
    property string busy: ""                     // "cat.opt" of the action in progress, or ""
    property var needs: ({})                     // toggle key → what to do while it is off
    property var current: ({})                   // "cat.opt" → value

    readonly property var types: ["toggle", "choice", "slider", "action", "info"]

    function find(catId: string, optId: string): var {
        for (const c of categories)
            if (c.id === catId)
                return c.options.find(o => o.id === optId) ?? null;
        return null;
    }

    function value(catId: string, optId: string): var {
        const opt = find(catId, optId);
        if (opt?.setting)
            return Math.max(0, Settings.levelsOf(opt.setting).indexOf(Settings.levelOf(opt.setting)));
        const k = catId + "." + optId;
        return Object.prototype.hasOwnProperty.call(current, k) ? current[k] : null;
    }

    // The text of a value of `opt`, as the row and the card show it.
    function textOf(opt: var, v: var): string {
        switch (opt?.type) {
        case "toggle":
            return v ? Strings.settings.on : Strings.settings.off;
        case "choice":
            return String(opt.values[v] ?? "");
        case "slider":
            return v === null || v === undefined ? "" : String(v);
        case "action":
        case "info":
            return String(opt.text ?? "");
        }
        return "";
    }

    function display(catId: string, optId: string): string {
        return textOf(find(catId, optId), value(catId, optId));
    }

    function defaultDisplay(catId: string, optId: string): string {
        const opt = find(catId, optId);
        return hasValue(opt) ? textOf(opt, opt.default) : "";
    }

    function hasValue(opt: var): bool {
        return opt?.type === "toggle" || opt?.type === "choice" || opt?.type === "slider";
    }

    // An option that `needs` a toggle which is off (FR-017).
    function isDimmed(catId: string, optId: string): bool {
        const opt = find(catId, optId);
        if (!opt?.needs)
            return false;
        for (const c of categories)
            for (const o of c.options)
                if (o.type === "toggle" && o.key === opt.needs)
                    return value(c.id, o.id) === false;
        return false;
    }

    function needsText(catId: string, optId: string): string {
        const opt = find(catId, optId);
        return opt?.needs ? String(needs[opt.needs] ?? "") : "";
    }

    // Every dimmed option, as "cat.opt" (for `settings dump`).
    function dimmedIds(): var {
        const out = [];
        for (const c of categories)
            for (const o of c.options)
                if (isDimmed(c.id, o.id))
                    out.push(c.id + "." + o.id);
        return out;
    }

    function set(catId: string, optId: string, v: var): void {
        const opt = find(catId, optId);
        if (opt?.setting)
            Settings.setSession(opt.setting, Settings.levelsOf(opt.setting)[v] ?? "");
        const next = Object.assign({}, current);
        next[catId + "." + optId] = v;
        current = next;
    }

    // ← / →: toggle flips; choice moves without wrapping; slider moves one step, 0–100.
    function step(catId: string, optId: string, dir: int): void {
        const opt = find(catId, optId);
        if (!opt || isDimmed(catId, optId))
            return;
        const v = value(catId, optId);
        if (opt.type === "toggle")
            set(catId, optId, !v);
        else if (opt.type === "choice")
            set(catId, optId, Math.max(0, Math.min(opt.values.length - 1, v + dir)));
        else if (opt.type === "slider")
            set(catId, optId, Math.max(0, Math.min(100, v + dir * opt.step)));
    }

    // Enter: toggle flips; choice advances, wrapping; action shows its note for a while.
    function activate(catId: string, optId: string): void {
        const opt = find(catId, optId);
        if (!opt || isDimmed(catId, optId))
            return;
        const v = value(catId, optId);
        if (opt.type === "toggle")
            set(catId, optId, !v);
        else if (opt.type === "choice")
            set(catId, optId, (v + 1) % opt.values.length);
        else if (opt.type === "action") {
            busy = catId + "." + optId;
            busyTimer.restart();
        }
    }

    // A click on a slider's track: `v` is the clicked fraction, 0–1.
    function pick(catId: string, optId: string, v: real): void {
        const opt = find(catId, optId);
        if (opt?.type !== "slider" || isDimmed(catId, optId))
            return;
        set(catId, optId, Math.max(0, Math.min(100, Math.round(v * 100))));
    }

    function reset(): void {
        const next = {};
        for (const c of categories)
            for (const o of c.options) {
                if (o.setting)
                    Settings.setSession(o.setting, "");     // back to shell.json / defaults.json
                else if (hasValue(o))
                    next[c.id + "." + o.id] = o.value;
            }
        current = next;
        busy = "";
        busyTimer.stop();
    }

    function dumpValues(): var {
        const out = {};
        for (const c of categories) {
            out[c.id] = {};
            for (const o of c.options)
                out[c.id][o.id] = display(c.id, o.id);
        }
        return out;
    }

    // --- loading --------------------------------------------------------------------------------
    // A short reason when the catalog can't be used, "" when it can (contracts/settings.schema.json).
    function problemOf(data: var): string {
        if (!data || typeof data !== "object" || !Array.isArray(data.categories) || data.categories.length === 0)
            return "no categories";
        for (const c of data.categories) {
            if (typeof c?.id !== "string" || typeof c.label !== "string" || !Array.isArray(c.options))
                return `bad category ${JSON.stringify(c?.id ?? null)}`;
            for (const o of c.options) {
                const where = `${c.id}.${o?.id}`;
                if (typeof o?.id !== "string" || typeof o.label !== "string" || !types.includes(o.type))
                    return `bad option ${where}`;
                if (o.type === "toggle" && typeof o.value !== "boolean")
                    return `${where}: a toggle's value is a boolean`;
                if (o.type === "choice" && !(Array.isArray(o.values) && o.values.length >= 2
                        && Number.isInteger(o.value) && o.value >= 0 && o.value < o.values.length))
                    return `${where}: a choice needs values and an index`;
                if (o.type === "slider" && !(Number.isInteger(o.value) && o.value >= 0 && o.value <= 100
                        && Number.isInteger(o.step) && o.step >= 1))
                    return `${where}: a slider needs a value 0–100 and a step`;
                if (o.setting !== undefined && !(o.type === "choice"
                        && Settings.levelsOf(String(o.setting)).length === o.values.length))
                    return `${where}: a live setting is a choice over the setting's levels`;
            }
        }
        return "";
    }

    function load(text: string): void {
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (e) {
            fail(`${catalogPath} is not valid JSON (${e})`);
            return;
        }
        const problem = problemOf(data);
        if (problem !== "") {
            fail(`${catalogPath}: ${problem}`);
            return;
        }
        needs = data.needs ?? {};
        categories = data.categories;
        error = "";
        reset();
    }

    function fail(reason: string): void {
        console.warn(`settings: ${reason}`);
        categories = [];
        needs = {};
        current = {};
        busy = "";
        error = Strings.settings.error;
    }

    onCatalogPathChanged: if (catalogPath === "") fail("no catalog file")
    Component.onCompleted: if (catalogPath === "") fail("no catalog file")

    FileView {
        id: file
        path: root.catalogPath
        printErrors: false
        blockLoading: true
        onLoaded: root.load(text())
        onLoadFailed: root.fail(`cannot read ${path}`)
    }

    Timer {
        id: busyTimer
        interval: Tokens.motion.actionBusy
        onTriggered: root.busy = ""
    }
}
