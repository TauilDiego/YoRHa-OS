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
// spec 019 (contracts/system-provider.md): a third live source. "setting": "sys.<provider>.<key>" asks
// a provider (SysProviders) what the system says. Such a row has no value in the catalog and none
// saved here, so it only ever shows what the provider says (FR-002): a choice's values come from
// labelsOf, an info's text from levelOf, and it dims with the provider's reason (FR-004). "opens" does
// the same for an action that shows a read-only list. "requires": "<capability>" makes a row disappear
// where the compositor can't do it (FR-045): `visibleCategories` is the list every screen uses.
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
    // spec 019 (research R5): the SYSTEM category on screen, "" with the page out of view. Providers
    // re-read what raises no event only while their category is open.
    property string watching: ""

    // spec 013 (front C): "multi", a list of marks (value: the marked indices of `values`), bound to a
    // Settings key of type "layouts" by "setting"; its `ids` are the XKB layout names.
    readonly property var types: ["toggle", "choice", "slider", "action", "info", "multi"]

    // spec 019 (FR-045): the catalog without the rows this compositor can't do, and without a category
    // that lost them all. (A category with no rows of its own is only a test catalog's; it stays.)
    readonly property var visibleCategories: {
        const out = [];
        for (const c of categories) {
            const options = c.options.filter(o => !o.requires || Compositor.supports(String(o.requires)));
            if (options.length > 0 || c.options.length === 0)
                out.push(Object.assign({}, c, { options: options }));
        }
        return out;
    }
    // Every row out of sight on this compositor, as "cat.opt" (for `settings dump`).
    function hiddenIds(): var {
        const out = [];
        for (const c of categories)
            for (const o of c.options)
                if (o.requires && !Compositor.supports(String(o.requires)))
                    out.push(c.id + "." + o.id);
        return out;
    }

    function find(catId: string, optId: string): var {
        for (const c of categories)
            if (c.id === catId)
                return c.options.find(o => o.id === optId) ?? null;
        return null;
    }

    // --- live options (004 acabamento; spec 008) -----------------------------------------------------
    // The source of a live option: { src, key }; src is Settings, NotifyPrefs or a Sys* provider.
    function sysOf(k: string): var {
        const dot = k.indexOf(".", 4);
        return { src: SysProviders.byName(k.slice(4, dot)), key: k.slice(dot + 1), notify: false, sys: true };
    }
    function liveOf(opt: var): var {
        const k = String(opt?.setting ?? "");
        if (k === "")
            return null;
        if (k.startsWith("sys."))
            return sysOf(k);
        return k.startsWith("notify.") ? { src: NotifyPrefs, key: k.slice(7), notify: true } : { src: Settings, key: k, notify: false };
    }
    function isLive(catId: string, optId: string): bool {
        return liveOf(find(catId, optId)) !== null;
    }
    // The option as the page draws it: a notifications option takes its texts from Strings.notify and
    // its values from NotifyPrefs (the Monitor option lists the outputs).
    function resolve(opt: var): var {
        // spec 019: what the provider says, never the catalog (FR-002). No values yet: one dash.
        if (String(opt?.setting ?? "").startsWith("sys.")) {
            const p = sysOf(opt.setting);
            if (opt.type === "choice") {
                const labels = p.src.labelsOf(p.key);
                return Object.assign({}, opt, { values: labels.length > 0 ? labels : [Strings.settings.sys.empty] });
            }
            return opt.type === "info" ? Object.assign({}, opt, { text: String(p.src.levelOf(p.key) ?? "") }) : opt;
        }
        // spec 019 (FR-033): a "levels" setting's values come from Settings, with one off the list.
        if (isLevels(opt))
            return Object.assign({}, opt, { values: Settings.labelsOf(String(opt.setting)) });
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
    // Is this a choice over a Settings key of type "levels"?
    function isLevels(opt: var): bool {
        return opt?.type === "choice" && Settings.keys[Settings.keyOf(String(opt?.setting ?? ""))]?.type === "levels";
    }
    // Every live option on screen, as "cat.opt" (for `settings dump`).
    function liveIds(): var {
        const out = [];
        for (const c of visibleCategories)
            for (const o of c.options)
                if (o.setting || o.opens)
                    out.push(c.id + "." + o.id);
        return out;
    }

    // --- spec 019: what a provider adds to a row -------------------------------------------------
    // The source of a row that `opens` a read-only list, or null.
    function opensOf(opt: var): var {
        const k = String(opt?.opens ?? "");
        return k.startsWith("sys.") ? sysOf(k) : null;
    }
    // The provider behind a row (its setting or what it opens), or null.
    function sysSource(opt: var): var {
        const k = String(opt?.setting ?? "");
        return k.startsWith("sys.") ? sysOf(k) : opensOf(opt);
    }
    function isSys(opt: var): bool {
        return sysSource(opt) !== null;
    }
    function rangeOf(l: var): var {
        const r = typeof l.src.rangeOf === "function" ? l.src.rangeOf(l.key) : null;
        return { min: Number(r?.min ?? 0), max: Number(r?.max ?? 100) };
    }
    // The stable ids of a live list (FR-003), for the pop-up that follows it; null where there is no list.
    function levelIds(opt: var): var {
        const l = liveOf(opt);
        return l?.sys && opt.type === "choice" ? l.src.levelsOf(l.key) : null;
    }
    // The texts the pop-up shows for `opt`, now.
    function popupValues(opt: var): var {
        const o = opensOf(opt);
        if (o) {
            const rows = typeof o.src.listOf === "function" ? o.src.listOf(o.key) : [];
            return rows.length > 0 ? rows : [Strings.settings.sys.empty];
        }
        return resolve(opt).values ?? [];
    }
    // The provider's note for the card: a refused write, a muted microphone…
    function noteOf(opt: var): string {
        const l = sysSource(opt);
        return l && typeof l.src.note === "function" ? String(l.src.note(l.key) ?? "") : "";
    }
    // The card's rows before NOW (the screen's name).
    function metaOf(opt: var): var {
        const l = sysSource(opt);
        const m = l && typeof l.src.metaOf === "function" ? l.src.metaOf(l.key) : [];
        return Array.isArray(m) ? m : [];
    }
    // Why each dimmed sys row is dimmed, as { "cat.opt": reason } (for `settings dump`).
    function reasons(): var {
        const out = {};
        for (const c of visibleCategories)
            for (const o of c.options) {
                const l = sysSource(o);
                if (l && !l.src.available(l.key))
                    out[c.id + "." + o.id] = String(l.src.reason(l.key) ?? "");
            }
        return out;
    }

    function value(catId: string, optId: string): var {
        const opt = find(catId, optId);
        const l = liveOf(opt);
        // spec 019 (SC-002): the provider has nothing to read, so the row has no value to show.
        if (l?.sys && (opt.type === "slider" || opt.type === "toggle") && (l.src.levelOf(l.key) ?? null) === null)
            return null;
        if (l?.sys && opt.type === "slider") {       // held to the track; display() says the real number
            const r = rangeOf(l);
            return Math.max(r.min, Math.min(r.max, Number(l.src.levelOf(l.key)) || 0));
        }
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
        return opt?.type === "multi" || opensOf(opt) !== null || (opt?.type === "choice" && resolve(opt).values.length > 3);
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
            return String(opt.text ?? "");
        case "info":
            return String(resolve(opt).text ?? "");
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
        const opt = find(catId, optId);
        const l = liveOf(opt);
        if (l?.sys && (opt.type === "slider" || opt.type === "toggle") && value(catId, optId) === null)
            return "";                               // nothing to read, nothing invented (SC-002)
        if (l?.sys && opt.type === "slider")         // the real number, also above the track's top
            return String(Number(l.src.levelOf(l.key)) || 0);
        return textOf(opt, value(catId, optId));
    }

    function defaultDisplay(catId: string, optId: string): string {
        const opt = find(catId, optId);
        // spec 019: where `settings reset` goes back to, the configured value
        if (isLevels(opt)) {
            const k = Settings.keyOf(String(opt.setting));
            return Settings.levelLabel(k, Settings.configuredOf(k));
        }
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
        const sys = sysSource(opt);                  // spec 019 (FR-004): what this machine lacks
        if (sys)
            return !sys.src.available(sys.key);
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
        const sys = sysSource(opt);
        if (sys)
            return String(sys.src.reason(sys.key) ?? "");
        return opt?.needs ? String(needs[opt.needs] ?? "") : "";
    }

    // Every dimmed option, as "cat.opt" (for `settings dump`).
    function dimmedIds(): var {
        const out = [];
        for (const c of visibleCategories)
            for (const o of c.options)
                if (isDimmed(c.id, o.id))
                    out.push(c.id + "." + o.id);
        return out;
    }

    function set(catId: string, optId: string, v: var): void {
        const opt = find(catId, optId);
        const l = liveOf(opt);
        if (l?.sys) {                                // spec 019: nothing is saved here (FR-017)
            if (opt.type === "toggle")
                l.src.setLevel(l.key, v === true);
            else if (opt.type === "slider")
                l.src.setLevel(l.key, v);
            else if (opt.type === "choice" && l.src.levelsOf(l.key)[v] !== undefined)
                l.src.setLevel(l.key, l.src.levelsOf(l.key)[v]);
            return;
        }
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
        else if (opt.type === "slider") {
            // spec 019: a sys row moves from the real number. Off the track, only towards it counts
            // (above the top, ← goes down from the real one and → does nothing).
            const l = liveOf(opt);
            if (l?.sys) {
                const r = rangeOf(l), real = Number(l.src.levelOf(l.key)) || 0;
                if (dir > 0 ? real >= r.max : real <= r.min)
                    return;
                set(catId, optId, dir > 0 ? Math.min(r.max, real + opt.step) : Math.max(r.min, real - opt.step));
                Sounds.play("change");
                return;
            }
            set(catId, optId, Math.max(0, Math.min(100, v + dir * opt.step)));
        }
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
            const next = (v + 1) % resolve(opt).values.length;
            set(catId, optId, next);
            if (next !== v)                      // spec 019: one output only, nothing changed
                Sounds.play("change");           // spec 013, front D
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
        const l = liveOf(opt);
        const r = l?.sys ? rangeOf(l) : { min: 0, max: 100 };
        set(catId, optId, Math.max(r.min, Math.min(r.max, Math.round(v * 100))));
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
        const providers = new Set();
        for (const c of categories)
            for (const o of c.options) {
                const sys = sysSource(o);
                if (sys)
                    providers.add(sys.src);               // FR-006: the system's values stay as they are
                else if (o.setting && !liveOf(o).notify)
                    Settings.setLevel(o.setting, "");     // back to shell.json / defaults.json
            }
        for (const p of providers)
            if (typeof p.resetSaved === "function")
                p.resetSaved();                           // FR-029: only what the product saved
        initValues();
    }

    function dumpValues(): var {
        const out = {};
        for (const c of visibleCategories) {
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
                // spec 019 (FR-002, FR-010): a row the system answers has no value of its own.
                const sysKey = String(o.setting ?? "");
                if (sysKey.startsWith("sys.")) {
                    const problem = sysProblem(sysKey, o);
                    if (problem !== "")
                        return `${where}: ${problem}`;
                    continue;
                }
                if (o.opens !== undefined && !(o.type === "action" && String(o.opens).startsWith("sys.")
                        && sysOf(String(o.opens)).src !== null))
                    return `${where}: opens is an action over a known provider`;
                if (o.requires !== undefined && typeof o.requires !== "string")
                    return `${where}: requires names a capability`;
                if (isLevels(o))
                    continue;
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

    // "" when a "sys.<provider>.<key>" row is well formed, else what is wrong.
    function sysProblem(k: string, o: var): string {
        if (k.indexOf(".", 4) < 0 || sysOf(k).src === null)
            return `no provider for ${k}`;
        if (!["choice", "slider", "toggle", "info"].includes(o.type))
            return "a system row is a choice, a slider, a toggle or an info";
        if (o.value !== undefined || o.values !== undefined || o.default !== undefined)
            return "a system row has no value, values or default in the catalog";
        if (o.type === "slider" && !(Number.isInteger(o.step) && o.step >= 1))
            return "a slider needs a step";
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

    // spec 015: the catalog's texts name the product as the repository does (YoRHa-Shell, the
    // yorha-shell folders, the `yorha` command); the installed product's own names go in their place,
    // so a renamed product (FR-017) never shows the old name.
    function named(text: string): string {
        const esc = v => JSON.stringify(String(v)).slice(1, -1);
        const swap = (t, from, to) => t.split(from).join(to);          // (no String.replaceAll in QML's JS)
        return swap(swap(swap(text, "YoRHa-Shell", esc(Product.pretty)), "yorha-shell", esc(Product.name)),
                    "`yorha ", "`" + esc(Product.cmd) + " ");
    }

    function load(text: string): void {
        let data = null;
        try {
            data = JSON.parse(named(text));
        } catch (e) {
            fail(`${catalogPath} is not valid JSON (${e})`);
            return;
        }
        const problem = problemOf(data);
        if (problem !== "") {
            fail(`${catalogPath}: ${problem}`);
            return;
        }
        forgetRetired();
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

    // spec 019 (FR-007): what the fake rows saved, gone for good, whichever catalog is in use. A value
    // that was only ever made up is never applied to the system.
    readonly property var retired: [
        "settings.sound.output", "settings.sound.volume", "settings.sound.mute", "settings.sound.mic",
        "settings.display.resolution", "settings.display.refresh", "settings.display.scale", "settings.display.brightness",
        "settings.keyboard.caps", "settings.keyboard.delay", "settings.keyboard.rate",
        "settings.appearance.ui-scale", "settings.appearance.bar-height"
    ]
    function forgetRetired(): void {
        if (SettingsState.persisted)
            SettingsState.patch({}, retired);
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
