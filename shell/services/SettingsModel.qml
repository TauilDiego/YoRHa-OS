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
// (Settings.levelOf), and changing it changes and saves the setting (Settings.setLevel).
// spec 008: the same live mechanism, extended. "setting": "notify.<key>" binds a choice or a toggle
// to NotifyPrefs (levelsOf / levelOf / setLevel, the notifications' options, saved by NotifyPrefs as
// "notifications.<key>"); its label, description and value labels come from Strings.notify, and the
// Monitor option's values are the outputs (resolve()). reset() leaves them alone: the notifications
// have their own reset (`notify prefsReset`).
// Options are addressed by category id + option id; "cat.opt" keys the maps below.
// "Salvar sempre" (owner, 2026-10-27; spec 004 amendment (3)): every value changed here is saved in
// SettingsState as "settings.<cat>.<opt>" (unless the option says "persist": false) and wins over
// the catalog's value after a restart. reset() clears what was saved.
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

    // spec 013 (front C): "multi", a list of marks (value: the marked indices of `values`), bound to a
    // Settings key of type "layouts" by "setting"; its `ids` are the XKB layout names.
    readonly property var types: ["toggle", "choice", "slider", "action", "info", "multi"]

    function find(catId: string, optId: string): var {
        for (const c of categories)
            if (c.id === catId)
                return c.options.find(o => o.id === optId) ?? null;
        return null;
    }

    // --- live options (004 acabamento; spec 008) -----------------------------------------------------
    // The source of a live option: { src, key }; src is Settings or NotifyPrefs.
    function liveOf(opt: var): var {
        const k = String(opt?.setting ?? "");
        if (k === "")
            return null;
        return k.startsWith("notify.") ? { src: NotifyPrefs, key: k.slice(7), notify: true } : { src: Settings, key: k, notify: false };
    }
    function isLive(catId: string, optId: string): bool {
        return liveOf(find(catId, optId)) !== null;
    }
    // The option as the page draws it: a notifications option takes its texts from Strings.notify and
    // its values from NotifyPrefs (the Monitor option lists the outputs).
    function resolve(opt: var): var {
        // spec 014: SYSTEM › Updates' rows come from the Updater.
        if (opt?.updates === "installed" || opt?.updates === "available")
            return Object.assign({}, opt, { text: Updater.text(opt.updates) });
        // spec 015: the sign's forms take their labels from Strings.updates.
        if (opt?.setting === "updates.sign")
            return Object.assign({}, opt, { values: Strings.updates.signLabels });
        const l = liveOf(opt);
        // spec 013, front D: the sound folder's info row shows the path in use (the catalog's text
        // is "ours", the built-in sounds).
        if (l && opt.type === "info" && l.key === "sound.folder")
            return Settings.soundFolder !== "" ? Object.assign({}, opt, { text: Settings.soundFolder }) : opt;
        if (!l?.notify)
            return opt;
        const N = Strings.notify;
        const out = Object.assign({}, opt, {
            label: N.prefLabels[l.key] ?? opt.label,
            desc: N.prefDescs[l.key] ?? opt.desc ?? ""
        });
        if (opt.type === "choice")
            out.values = NotifyPrefs.labelsOf(l.key);
        return out;
    }
    // Every live option, as "cat.opt" (for `settings dump`).
    function liveIds(): var {
        const out = [];
        for (const c of categories)
            for (const o of c.options)
                if (o.setting)
                    out.push(c.id + "." + o.id);
        return out;
    }

    function value(catId: string, optId: string): var {
        const opt = find(catId, optId);
        const l = liveOf(opt);
        if (l && opt.type === "toggle")
            return l.src.levelOf(l.key) === true;
        if (l && opt.type === "multi")
            return markedOf(opt);
        if (l && opt.type === "slider")          // spec 013: sound.volume
            return Number(l.src.levelOf(l.key));
        if (l && opt.type === "choice")
            return Math.max(0, l.src.levelsOf(l.key).indexOf(l.src.levelOf(l.key)));
        const k = catId + "." + optId;
        const saved = opt?.persist === false ? undefined : SettingsState.get("settings." + k, undefined);
        if (saved !== undefined && validValue(opt, saved))
            return saved;
        return Object.prototype.hasOwnProperty.call(current, k) ? current[k] : null;
    }

    // --- spec 013, front C: the marks of a "multi" option and the popup's rule ----------------------
    // The marked indices of `opt` (ascending): the saved layouts, else the compositor's current ones,
    // else the first value; a layout the option doesn't list is dropped.
    function markedOf(opt: var): var {
        const saved = Settings.valueOf(Settings.keyOf(String(opt.setting)));
        const from = saved.length > 0 ? saved : Compositor.keyboardLayouts;
        const out = [];
        opt.ids.forEach((id, i) => {
            if (from.includes(id))
                out.push(i);
        });
        return out.length > 0 ? out : [0];
    }
    // Save the marked indices of a "multi" option (never none: the caller keeps one marked).
    function setMarked(catId: string, optId: string, marked: var): void {
        const opt = find(catId, optId);
        if (opt?.type !== "multi" || !Array.isArray(marked) || marked.length === 0)
            return;
        const ids = opt.ids.filter((id, i) => marked.includes(i));
        const err = Settings.setKey(Settings.keyOf(String(opt.setting)), ids);
        if (err !== "")
            console.warn(`settings: ${catId}.${optId}: ${err}`);
    }
    // Enter opens the choice pop-up (FR-025, FR-026): a choice of more than 3 values, or a "multi".
    function opensPopup(opt: var): bool {
        return opt?.type === "multi" || (opt?.type === "choice" && resolve(opt).values.length > 3);
    }
    // --- end front C ---------------------------------------------------------------------------------

    // Is `v` a value `opt` can take (a saved value is checked before it is used)?
    function validValue(opt: var, v: var): bool {
        switch (opt?.type) {
        case "toggle":
            return typeof v === "boolean";
        case "choice":
            return Number.isInteger(v) && v >= 0 && v < opt.values.length;
        case "slider":
            return Number.isInteger(v) && v >= 0 && v <= 100;
        }
        return false;
    }

    // The text of a value of `opt`, as the row and the card show it.
    function textOf(opt: var, v: var): string {
        switch (opt?.type) {
        case "toggle":
            return v ? Strings.settings.on : Strings.settings.off;
        case "choice":
            return String(resolve(opt).values[v] ?? "");
        case "slider":
            return v === null || v === undefined ? "" : String(v);
        case "multi":
            return Array.isArray(v) ? v.map(i => String(opt.ids[i] ?? "").toUpperCase()).join(" · ") : "";
        case "action":
        case "info":
            return String(opt.text ?? "");
        }
        return "";
    }

    // spec 007: the stable id of a choice's value in use (its `ids`), "" without `ids`, without the
    // option or out of range. Bindings that call it follow the value live (it reads `current`).
    function choiceId(catId: string, optId: string): string {
        const opt = find(catId, optId);
        if (opt?.type !== "choice" || !Array.isArray(opt.ids))
            return "";
        return String(opt.ids[value(catId, optId)] ?? "");
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
        if (opt?.updates === "now")                  // spec 014: only with a newer version
            return !Updater.available;
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
        if (opt?.updates === "now")
            return Updater.installed ? Strings.updates.noNewer : Strings.updates.notInstalled;
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
        const l = liveOf(opt);
        if (l?.notify) {
            l.src.setLevel(l.key, opt.type === "toggle" ? v === true : l.src.levelsOf(l.key)[v]);
            return;
        }
        if (opt?.setting && (opt.type === "toggle" || opt.type === "slider"))
            Settings.setLevel(opt.setting, v);      // spec 013: sound.ui, sound.volume, …
        else if (opt?.setting)
            Settings.setLevel(opt.setting, Settings.levelsOf(opt.setting)[v] ?? "");
        else if (opt && opt.persist !== false)
            SettingsState.set("settings." + catId + "." + optId, v);
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
            set(catId, optId, Math.max(0, Math.min(resolve(opt).values.length - 1, v + dir)));
        else if (opt.type === "slider")
            set(catId, optId, Math.max(0, Math.min(100, v + dir * opt.step)));
        if (value(catId, optId) !== v)
            Sounds.play("change");               // spec 013, front D: after the set, at the new volume
    }

    // Enter: toggle flips; choice advances, wrapping; action shows its note for a while.
    function activate(catId: string, optId: string): void {
        const opt = find(catId, optId);
        if (!opt || isDimmed(catId, optId))
            return;
        const v = value(catId, optId);
        if (opt.type === "toggle") {
            set(catId, optId, !v);
            Sounds.play("change");               // spec 013, front D
        } else if (opt.type === "choice") {
            set(catId, optId, (v + 1) % resolve(opt).values.length);
            Sounds.play("change");               // spec 013, front D
        } else if (opt.type === "action") {
            Sounds.play("confirm");              // spec 013, front D
            if (opt.updates === "now")           // spec 014: the terminal runs `yorha update`
                Updater.updateNow();
            // spec 013, front D: an action with `clears` saves "" for that setting (Sound › Use
            // ours: the sound folder back to the built-in sounds, even over a shell.json folder).
            if (opt.clears && Settings.keyOf(String(opt.clears)))
                Settings.setKey(Settings.keyOf(String(opt.clears)), "");
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
        Sounds.play("change");                   // spec 013, front D
    }

    // The catalog's values; what was saved still wins (value()).
    function initValues(): void {
        const next = {};
        for (const c of categories)
            for (const o of c.options)
                if (!o.setting && hasValue(o))
                    next[c.id + "." + o.id] = o.value;
        current = next;
        busy = "";
        busyTimer.stop();
    }

    // Back to the catalog and the config: the saved values are cleared too.
    function reset(): void {
        SettingsState.clear("settings.");
        for (const c of categories)
            for (const o of c.options)
                if (o.setting && !liveOf(o).notify)
                    Settings.setLevel(o.setting, "");     // back to shell.json / defaults.json
        initValues();
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
                if (o.ids !== undefined && !((o.type === "choice" || o.type === "multi") && Array.isArray(o.ids) && o.ids.length === o.values.length
                        && o.ids.every(x => typeof x === "string" && x !== "") && new Set(o.ids).size === o.ids.length))
                    return `${where}: ids are one unique, non-empty string per value`;
                if (o.type === "slider" && !(Number.isInteger(o.value) && o.value >= 0 && o.value <= 100
                        && Number.isInteger(o.step) && o.step >= 1))
                    return `${where}: a slider needs a value 0–100 and a step`;
                const live = o.setting === undefined ? null : liveOf(o);
                if (live?.notify && !((o.type === "choice" || o.type === "toggle")
                        && NotifyPrefs.levelsOf(live.key).length > 0))
                    return `${where}: a notifications setting is a choice or a toggle over a known option`;
                if (o.type === "multi" && !(Array.isArray(o.values) && o.values.length >= 2 && Array.isArray(o.ids)
                        && o.ids.length === o.values.length && new Set(o.ids).size === o.ids.length
                        && Settings.keys[Settings.keyOf(String(o.setting))]?.type === "layouts"
                        && o.ids.every(x => Settings.validKey(Settings.keyOf(String(o.setting)), [x]))))
                    return `${where}: a multi is a list of layouts over a layouts setting, with one id per value`;
                if (live && !live.notify && o.type !== "multi" && !liveFits(o))
                    return `${where}: a live setting is a choice over the setting's levels (or, spec 013, a toggle of a yes/no one, a slider of a 0–100 one, an info of a text one)`;
                if (o.type === "action" && o.clears !== undefined && !Settings.keyOf(String(o.clears)))
                    return `${where}: clears names no shell setting`;
            }
        }
        return "";
    }

    // Does a live (non-notification) option fit the shell setting it names?
    function liveFits(o: var): bool {
        const key = Settings.keyOf(String(o.setting));
        const t = key ? Settings.keys[key] : null;
        switch (o.type) {
        case "choice":
            return Settings.levelsOf(String(o.setting)).length === o.values.length;
        case "toggle":
            return t?.type === "bool";
        case "slider":
            return t?.type === "int" && t.min === 0 && t.max === 100;
        case "info":
            return t?.type === "string";
        }
        return false;
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
        initValues();
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
