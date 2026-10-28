pragma Singleton

import QtQuick
import Quickshell
import "../strings"

// The notifications' options and do not disturb (spec 008, FR-026, FR-039–FR-043). Each value is,
// in order of precedence: the user's saved choice (SettingsState, "notifications.<key>"), the user's
// shell.json (block "notifications"), the project's defaults (config/defaults.json). With fixtures,
// the fixture's "notifications.prefs"/"dnd" take the config's place and SettingsState lives in memory
// only (FR-043), cleared whenever the fixture changes.
// The settings pop-up's Notifications category drives these through the same live-setting API the
// shell's Settings has (levelsOf / levelOf / setLevel, contracts: specs/004-wallpaper-system/
// contracts/settings-state.md): an option with "setting": "notify.<key>" in the catalog.
Singleton {
    id: root

    readonly property string prefix: "notifications."
    readonly property var keys: ["position", "osdPosition", "voice", "log", "logSize", "monitor", "onScreen", "duration", "typing", "fullscreen"]

    readonly property var fixture: Fixtures.has("notifications") ? (Fixtures.get("notifications") ?? {}) : null
    readonly property var base: {
        const out = Object.assign({}, Settings.notifications);
        const f = fixture?.prefs;
        if (f && typeof f === "object")
            for (const k of keys)
                if (f[k] !== undefined && Settings.notificationValid(k, f[k]))
                    out[k] = f[k];
        return out;
    }
    readonly property bool baseDnd: fixture ? fixture.dnd === true : false

    // A saved value, when it is valid (an invalid one is dropped, so the file is rewritten).
    function saved(key: string): var {
        const v = SettingsState.get(prefix + key, undefined);
        if (v === undefined)
            return undefined;
        const ok = key === "dnd" ? typeof v === "boolean" : Settings.notificationValid(key, v);
        if (!ok) {
            console.info(`notifications: the saved ${key} (${JSON.stringify(v)}) is not an option, using the default`);
            Qt.callLater(() => SettingsState.remove(prefix + key));
            return undefined;
        }
        return v;
    }
    function value(key: string): var {
        const v = saved(key);
        if (v !== undefined)
            return v;
        return key === "dnd" ? baseDnd : base[key];
    }

    readonly property var current: {
        SettingsState.values;                    // re-evaluate on every change
        const out = { dnd: value("dnd") };
        for (const k of keys)
            out[k] = value(k);
        return out;
    }
    readonly property bool dnd: current.dnd === true
    readonly property string position: current.position
    readonly property string osdPosition: current.osdPosition
    readonly property string voice: current.voice
    readonly property string log: current.log
    readonly property int logSize: current.logSize
    readonly property string monitor: current.monitor
    readonly property int onScreen: current.onScreen
    readonly property string duration: current.duration
    readonly property bool typing: current.typing === true
    readonly property string fullscreen: current.fullscreen

    readonly property string voiceName: Strings.notify.voices[voice] ?? Strings.notify.voices.relay
    readonly property real durationFactor: duration === "short" ? 0.66 : duration === "long" ? 1.5 : 1

    function origin(key: string): string {
        if (SettingsState.has(prefix + key))
            return "state";
        if (!fixture && Settings.notificationsConfigured.user.includes(key))
            return "user";
        return "default";
    }

    // IPC and the log's options: "top", "50", "true"… → the option's value, or undefined.
    function parse(key: string, text: var): var {
        if (key === "dnd" || key === "typing") {
            if (text === true || text === "true" || text === "on")
                return true;
            if (text === false || text === "false" || text === "off")
                return false;
            return undefined;
        }
        if (key === "logSize" || key === "onScreen") {
            const n = Number(text);
            return Number.isInteger(n) ? n : undefined;
        }
        return text === undefined || text === null ? undefined : String(text);
    }

    // Change one option now (and save it, unless fixtures). "ok" or "error: …".
    function set(key: string, text: var): string {
        if (key !== "dnd" && !keys.includes(key))
            return `error: unknown option ${key} (${["dnd"].concat(keys).join(", ")})`;
        const v = parse(key, text);
        const valid = key === "dnd" ? typeof v === "boolean" : (v !== undefined && Settings.notificationValid(key, v));
        if (!valid) {
            const opts = key === "dnd" ? ["true", "false"] : key === "monitor" ? ["\"\"", "<output>"] : Settings.notificationChoices[key];
            return `error: ${key} takes ${opts.join(", ")}`;
        }
        SettingsState.set(prefix + key, v);
        return "ok";
    }

    function setDnd(on: bool): void {
        SettingsState.set(prefix + "dnd", on);
    }

    // Every option back to the config and the defaults; the saved choices are cleared.
    function reset(): void {
        SettingsState.clear(prefix);
    }

    // --- the live-setting API of the settings catalog ("setting": "notify.<key>") ----------------------
    // The values a choice steps through, in order (a toggle: [false, true]).
    function levelsOf(key: string): var {
        if (key === "dnd" || key === "typing")
            return [false, true];
        if (key === "monitor") {
            const names = Quickshell.screens.map(sc => sc.name);
            if (monitor !== "" && !names.includes(monitor))
                names.push(monitor);                 // a fixed monitor that is gone keeps its name
            return [""].concat(names);
        }
        return Settings.notificationChoices[key] ?? [];
    }
    // The labels of those values, as the option row shows them.
    function labelsOf(key: string): var {
        const N = Strings.notify;
        if (key === "monitor")
            return levelsOf(key).map(v => v === "" ? N.prefValues.monitor[0] : v);
        return N.prefValues[key] ?? [];
    }
    function levelOf(key: string): var {
        return current[key];
    }
    function setLevel(key: string, level: var): void {
        SettingsState.set(prefix + key, level);
    }

    function dump(): var {
        const out = Object.assign({}, current);
        const o = {};
        for (const k of ["dnd"].concat(keys))
            o[k] = origin(k);
        out.origin = o;
        return out;
    }

    // With fixtures, the in-memory choices last only until the fixture changes (FR-043).
    Connections {
        target: Fixtures
        function onSourceChanged(): void {
            if (!SettingsState.persisted)
                SettingsState.clear(root.prefix);
        }
    }
}
