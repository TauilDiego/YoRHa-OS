pragma Singleton

import QtQuick
import Quickshell

// The person's edited file wins (spec 019, contracts/file-rule.md, FR-026, FR-027, FR-039 to FR-043).
// A value changed in a menu lasts only while the file's value doesn't change, and the only thing that
// proves a change is comparing what the file says now with what it said last time: the "base".
//   Compositor: the base is what the compositor reads right after a reload, or at the shell's first
//   start in a session, before anything is reapplied (the lab proved that value is the file's, T003).
//   Shell: the base is the raw shell.json, never merged with defaults.json (FR-043).
// With fixtures nothing here runs. The base lives in SettingsState, in the same atomic write as what
// it forgets ("fileBase.compositor", "fileBase.shell"), and `settings reset` doesn't touch it.
Singleton {
    id: root

    readonly property bool active: SettingsState.persisted

    // { saved: the SettingsState key, file: configValues' key, base: the key in the base }
    readonly property var compositorRules: [
        { saved: "input.repeatDelay", file: "repeatDelay", base: "repeatDelay" },
        { saved: "input.repeatRate", file: "repeatRate", base: "repeatRate" },
        { saved: "input.capsRule", file: "kbOptions", part: "caps", base: "capsPart" },
        { saved: "input.kbLayouts", file: "kbLayout", base: "kbLayout" }
    ]
    // { saved, path: where in shell.json }. A key added to Settings.keys gets the rule by itself.
    readonly property var shellRules: {
        const out = [{ saved: "shell.barContrast", path: ["barContrast"] }];
        for (const k of Object.keys(Settings.keys))
            out.push({ saved: k, path: Settings.keys[k].config });
        for (const k of Object.keys(Settings.notificationFallback))
            out.push({ saved: "notifications." + k, path: ["notifications", k] });
        return out;
    }

    // --- Caps Lock: only the part of kb_options that is about Caps (research R3, FR-027) ------------
    readonly property var capsEntry: /^(caps:.+|ctrl:nocaps|ctrl:swapcaps.*)$/
    function entries(kbOptions: string): var {
        return String(kbOptions ?? "").split(",").map(x => x.trim()).filter(x => x !== "");
    }
    function capsPart(kbOptions: string): string {
        return entries(kbOptions).filter(x => root.capsEntry.test(x)).join(",");
    }
    // The person's entries first, then the rule: "grp:alt_shift_toggle,caps:escape".
    function mergeCaps(kbOptions: string, rule: string): string {
        const rest = entries(kbOptions).filter(x => !root.capsEntry.test(x));
        return (rule ? rest.concat([rule]) : rest).join(",");
    }

    // --- the compositor's file ----------------------------------------------------------------------
    function baseOf(values: var): var {
        return {
            repeatDelay: values.repeatDelay,
            repeatRate: values.repeatRate,
            capsPart: capsPart(values.kbOptions),
            kbLayout: values.kbLayout
        };
    }

    function compareCompositor(values: var, trigger: string, errors: var): void {
        if (!active || trigger === "poll" || !values)
            return;
        const session = Compositor.sessionId;
        const base = SettingsState.get("fileBase.compositor", null);
        // The shell came back in the same session: the compositor didn't read its file (FR-039).
        const sameSession = trigger === "start" && base !== null && base.session === session;
        // A config with errors says nothing about what the person wants (FR-042).
        if (!sameSession && errors.length === 0) {
            const now = baseOf(values);
            const forget = base?.values ? compositorRules.filter(r => now[r.base] !== base.values[r.base]).map(r => r.saved) : [];
            SettingsState.patch({ "fileBase.compositor": { session: session, values: now } }, forget);
        }
        applySaved();
    }

    // Set what the menu saved over the values read: only the keys that differ, none if none does.
    function applySaved(): void {
        const cur = Compositor.configValues;
        if (!active || !cur || !Compositor.supports("configFile"))
            return;
        const want = {};
        if (SettingsState.has("input.repeatDelay"))
            want.repeatDelay = SettingsState.get("input.repeatDelay", 0);
        if (SettingsState.has("input.repeatRate"))
            want.repeatRate = SettingsState.get("input.repeatRate", 0);
        if (SettingsState.has("input.capsRule"))
            want.kbOptions = mergeCaps(cur.kbOptions, String(SettingsState.get("input.capsRule", "")));
        const layouts = SettingsState.get("input.kbLayouts", []);
        if (Array.isArray(layouts) && layouts.length > 0)
            want.kbLayout = layouts.join(",");
        for (const k of Object.keys(want))
            if (want[k] === cur[k])
                delete want[k];
        if (Object.keys(want).length > 0)
            Compositor.setConfigValues(want);
    }

    // --- shell.json ---------------------------------------------------------------------------------
    function rawAt(user: var, path: var): var {
        let v = user;
        for (const p of path)
            v = v !== null && typeof v === "object" ? v[p] : undefined;
        return v;
    }
    function shellBaseOf(user: var): var {
        const out = {};
        for (const r of shellRules) {
            const v = rawAt(user, r.path);
            if (v !== undefined)
                out[r.saved] = v;
        }
        return out;
    }
    function compareShell(state: string): void {
        if (!active || state === "unreadable")     // FR-042: nothing is compared, nothing forgotten
            return;
        const now = shellBaseOf(state === "missing" ? {} : Settings.user);
        const base = SettingsState.get("fileBase.shell", null);
        const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
        const forget = base === null ? [] : shellRules.filter(r => !same(now[r.saved], base[r.saved])).map(r => r.saved);
        SettingsState.patch({ "fileBase.shell": now }, forget);
    }

    function dump(): var {
        return {
            compositor: SettingsState.get("fileBase.compositor", null),
            shell: SettingsState.get("fileBase.shell", null)
        };
    }

    Connections {
        target: Compositor
        function onConfigRead(values: var, trigger: string, errors: var): void {
            root.compareCompositor(values, trigger, errors);
        }
    }
    Connections {
        target: Settings
        function onUserFileRead(state: string): void {
            root.compareShell(state);
        }
    }
    // Fixtures cleared while running: this is the shell's first real look at the two files.
    onActiveChanged: {
        if (!active)
            return;
        Compositor.readConfig("start");
        Settings.rereadUser();
    }
}
