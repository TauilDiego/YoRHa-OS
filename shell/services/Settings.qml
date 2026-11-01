pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings: managed defaults (config/defaults.json) overridden key by key by the user's
// $XDG_CONFIG_HOME/yorha-os/shell.json. Updates never touch the user file (constitution III).
Singleton {
    id: root

    readonly property real uiScale: valid(merged.uiScale, 0.5, 3.0, "uiScale") ? merged.uiScale : defaults.uiScale
    readonly property int barHeight: Math.round(Math.max(28, Math.min(96, Number(merged.barHeight) || defaults.barHeight)))
    readonly property bool vignette: typeof merged.vignette === "boolean" ? merged.vignette : defaults.vignette
    readonly property bool wallpaperMotion: typeof merged.wallpaperMotion === "boolean" ? merged.wallpaperMotion : defaults.wallpaperMotion
    // Reduced motion: fades, the selector blink and wallpaper transitions become instant.
    readonly property bool reduceMotion: typeof merged.reduceMotion === "boolean" ? merged.reduceMotion : defaults.reduceMotion

    readonly property var defaults: parse(defaultsFile.text(), "defaults.json") ?? ({ uiScale: 1.0, barHeight: 68, vignette: true, wallpaperMotion: true, reduceMotion: false, barContrast: "normal", terminal: ["kitty"] })
    readonly property var user: userFile.loaded ? (parse(userFile.text(), userFile.path) ?? ({})) : ({})
    readonly property var merged: Object.assign({}, defaults, user)

    readonly property string userPath: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config");
        return xdg + "/yorha-os/shell.json";
    }

    function parse(text, name) {
        if (!text)
            return null;
        try {
            return JSON.parse(text);
        } catch (e) {
            console.warn(`settings: ${name} is not valid JSON, ignoring it (${e})`);
            return null;
        }
    }

    function valid(v, lo, hi, key) {
        if (v === undefined)
            return false;
        if (typeof v !== "number" || v < lo || v > hi) {
            console.warn(`settings: ${key} must be a number between ${lo} and ${hi}, using the default`);
            return false;
        }
        return true;
    }

    // --- spec 004: wallpaper (research R12) ---------------------------------------------------
    // The picture folder (`~` expanded), the transition and the camouflage's fine-tuning. A value
    // out of range falls back to the default with a warning. The wallpaper's own state (what is
    // applied, the last transition picked) lives in WallpaperStore, never in the user's config.
    readonly property string wallpaperFolder: {
        const v = typeof merged.wallpaperFolder === "string" && merged.wallpaperFolder !== ""
            ? merged.wallpaperFolder : (defaults.wallpaperFolder ?? "~/Pictures/Wallpapers");
        return v.startsWith("~/") ? Quickshell.env("HOME") + v.slice(1) : v;
    }
    readonly property var transitionKinds: ["camouflage", "wipe", "tiles", "crossfade"]
    readonly property string wallpaperTransition: {
        const v = merged.wallpaperTransition;
        if (transitionKinds.includes(v))
            return v;
        if (v !== undefined)
            console.warn(`settings: wallpaperTransition must be one of ${transitionKinds.join(", ")}, using the default`);
        return transitionKinds.includes(defaults.wallpaperTransition) ? defaults.wallpaperTransition : "camouflage";
    }
    // { cell, trail, glitch }, key by key: the user's value when valid, else the default.
    readonly property var camouflage: {
        const d = Object.assign({ cell: 24, trail: 2600, glitch: 2 }, defaults.camouflage ?? {});
        const u = merged.camouflage && typeof merged.camouflage === "object" ? merged.camouflage : {};
        const out = {};
        for (const k of ["cell", "trail", "glitch"]) {
            const err = u[k] === undefined ? "" : camouflageError(k, u[k]);
            if (err)
                console.warn(`settings: camouflage.${err}, using the default`);
            out[k] = u[k] !== undefined && !err ? u[k] : d[k];
        }
        return out;
    }

    // "" when `value` is valid for camouflage key `key`, else what is wrong (data-model.md).
    function camouflageError(key: string, value: var): string {
        if (key === "cell" && ![16, 24, 32].includes(value))
            return "cell must be 16, 24 or 32";
        if (key === "trail" && !(Number.isInteger(value) && value >= 400 && value <= 4000))
            return "trail must be a whole number of ms between 400 and 4000";
        if (key === "glitch" && ![0, 1, 2].includes(value))
            return "glitch must be 0, 1 or 2";
        return "";
    }
    // --- end spec 004 ----------------------------------------------------------------------------

    // --- 004 acabamento: the top bar's contrast ---------------------------------------------------
    // "normal" (the approved palettes) or "high" (a darker ink and a paper plate behind the texts
    // over paper, a heavier clock), from shell.json / defaults.json. The settings pop-up
    // (Appearance › Bar contrast) changes it live and saves it in SettingsState ("shell.barContrast"),
    // which wins over the config; its reset goes back to the configured value.
    readonly property var barContrastLevels: ["normal", "high"]
    readonly property string barContrastSaved: String(SettingsState.get("shell.barContrast", ""))
    readonly property string barContrastConfigured: {
        const v = merged.barContrast;
        if (barContrastLevels.includes(v))
            return v;
        if (v !== undefined)
            console.warn(`settings: barContrast must be one of ${barContrastLevels.join(", ")}, using the default`);
        return barContrastLevels.includes(defaults.barContrast) ? defaults.barContrast : "normal";
    }
    readonly property string barContrast: barContrastLevels.includes(barContrastSaved) ? barContrastSaved : barContrastConfigured

    // The shell settings the settings pop-up changes live: an option with `"setting": key` in the
    // catalog is a choice over these values, in this order (spec 013: or a toggle, over [true, false]).
    function levelsOf(key: string): var {
        if (key === "barContrast")
            return barContrastLevels;
        const k = keyOf(key);
        if (k && keys[k].type === "choice")
            return keys[k].values;
        if (k && keys[k].type === "bool")
            return [true, false];
        return [];
    }
    function levelOf(key: string): var {
        if (key === "barContrast")
            return barContrast;
        const k = keyOf(key);
        return k ? valueOf(k) : "";
    }
    // Save `level` for `key` (SettingsState, "shell.<key>"); "" goes back to shell.json / defaults.
    function setLevel(key: string, level: var): void {
        if (key !== "barContrast" && keyOf(key)) {
            setKey(keyOf(key), level === "" ? null : level);
            return;
        }
        if (levelsOf(key).includes(level))
            SettingsState.set("shell." + key, level);
        else
            SettingsState.remove("shell." + key);
    }
    // --- end 004 acabamento ------------------------------------------------------------------------

    // --- spec 013: the menus' presentation, the sounds and the keyboard layouts (data-model.md) ----
    // Each key: its type and the default when neither SettingsState (what the menus saved) nor
    // shell.json / defaults.json (`menuPresentation`, `sound.<x>`, `kbLayouts`) give a valid value.
    // A catalog option binds to one with "setting": "<key>" (the "shell." prefix may be left out).
    //   input.kbLayouts: [] = the compositor's layout as it is (the Keyboard › Layouts option fills it).
    readonly property var keys: ({
        "shell.menuPresentation": { type: "choice", values: ["floating", "fullscreen"], fallback: "floating", config: ["menuPresentation"] },
        "sound.ui": { type: "bool", fallback: true, config: ["sound", "ui"] },
        "sound.volume": { type: "int", min: 0, max: 100, fallback: 40, config: ["sound", "volume"] },
        "sound.folder": { type: "string", fallback: "", config: ["sound", "folder"] },
        "sound.bootLogin": { type: "bool", fallback: true, config: ["sound", "bootLogin"] },
        "input.kbLayouts": { type: "layouts", fallback: [], config: ["kbLayouts"] }
    })
    // The key of the table for `key` or "shell." + `key`, or "".
    function keyOf(key: string): string {
        return keys[key] ? key : keys["shell." + key] ? "shell." + key : "";
    }
    // Is `v` a value of `key`? (layouts: XKB layout names, e.g. "us", "br"; an empty list is the default only)
    function validKey(key: string, v: var): bool {
        const t = keys[key];
        switch (t?.type) {
        case "choice":
            return t.values.includes(v);
        case "bool":
            return typeof v === "boolean";
        case "int":
            return Number.isInteger(v) && v >= t.min && v <= t.max;
        case "string":
            return typeof v === "string";
        case "layouts":
            return Array.isArray(v) && v.length > 0 && v.every(x => typeof x === "string" && /^[a-z]{2,8}$/.test(x));
        }
        return false;
    }
    // From shell.json over defaults.json; a bad value falls back with an INFO line.
    function configuredOf(key: string): var {
        const t = keys[key];
        let v = merged;
        for (const p of t.config)
            v = v && typeof v === "object" ? v[p] : undefined;
        if (v === undefined || JSON.stringify(v) === JSON.stringify(t.fallback))
            return t.fallback;
        if (validKey(key, v))
            return v;
        console.info(`settings: ${t.config.join(".")} = ${JSON.stringify(v)} is not valid, using the default`);
        return t.fallback;
    }
    // What a menu saved (SettingsState) wins over the config.
    function valueOf(key: string): var {
        const saved = SettingsState.get(key, undefined);
        return saved !== undefined && validKey(key, saved) ? saved : configuredOf(key);
    }
    // Save `v` for `key`; null goes back to the config. "" on success, else what is wrong.
    function setKey(key: string, v: var): string {
        if (!keys[key])
            return `unknown key: ${key}`;
        if (v === null || v === undefined) {
            SettingsState.remove(key);
            return "";
        }
        if (!validKey(key, v))
            return `not a value of ${key}: ${JSON.stringify(v)}`;
        SettingsState.set(key, v);
        return "";
    }
    // valueOf reads SettingsState.values and the config, so these follow every change.
    readonly property string menuPresentation: valueOf("shell.menuPresentation")
    readonly property bool soundUi: valueOf("sound.ui")
    readonly property int soundVolume: valueOf("sound.volume")
    readonly property string soundFolder: valueOf("sound.folder")
    readonly property bool soundBootLogin: valueOf("sound.bootLogin")
    readonly property var kbLayouts: valueOf("input.kbLayouts")
    // --- end spec 013 --------------------------------------------------------------------------------

    // --- spec 007: the terminal that runs terminal apps (APPS, research R4) -----------------------
    // An argv prefix: a terminal app opens as [...terminal, "-e", ...its command]. A non-empty list
    // of non-empty strings; anything else falls back to the default with a warning.
    readonly property var terminal: {
        const ok = v => Array.isArray(v) && v.length > 0 && v.every(x => typeof x === "string" && x !== "");
        if (ok(merged.terminal))
            return merged.terminal;
        if (merged.terminal !== undefined)
            console.warn("settings: terminal must be a non-empty list of strings, using the default");
        return ok(defaults.terminal) ? defaults.terminal : ["kitty"];
    }
    // --- end spec 007 ----------------------------------------------------------------------------
    // --- spec 008: the notifications' options (FR-039, FR-040) ---------------------------------------
    // The project's defaults (defaults.json) overridden key by key by the user's shell.json, each value
    // checked against its options. NotifyPrefs puts the saved choices (SettingsState) on top.
    readonly property var notificationChoices: ({
        position: ["corner", "top", "subtitle"],
        osdPosition: ["bottom", "top"],
        voice: ["relay", "yorhaos", "system"],
        log: ["session", "saved"],
        logSize: [100, 50, 200],
        onScreen: [3, 1, 5],
        duration: ["normal", "short", "long"],
        typing: [true, false],
        fullscreen: ["hold", "show"]
    })
    readonly property var notificationFallback: ({
        position: "corner", osdPosition: "bottom", voice: "relay", log: "session", logSize: 100,
        monitor: "", onScreen: 3, duration: "normal", typing: true, fullscreen: "hold"
    })
    // Is `v` a value notification option `key` can take? (monitor: any output name, "" = focused)
    function notificationValid(key: string, v: var): bool {
        if (key === "monitor")
            return typeof v === "string";
        return (notificationChoices[key] ?? []).includes(v);
    }
    readonly property var notificationsDefault: {
        const d = defaults.notifications && typeof defaults.notifications === "object" ? defaults.notifications : {};
        const out = {};
        for (const k of Object.keys(notificationFallback))
            out[k] = notificationValid(k, d[k]) ? d[k] : notificationFallback[k];
        return out;
    }
    // { values, user: [keys from shell.json] }. A bad value is ignored with an INFO line (FR-037).
    readonly property var notificationsConfigured: {
        const u = user.notifications && typeof user.notifications === "object" ? user.notifications : {};
        const out = Object.assign({}, notificationsDefault);
        const fromUser = [];
        for (const k of Object.keys(notificationFallback)) {
            if (u[k] === undefined)
                continue;
            if (notificationValid(k, u[k])) {
                out[k] = u[k];
                fromUser.push(k);
            } else {
                console.info(`settings: notifications.${k} = ${JSON.stringify(u[k])} is not an option, using the default`);
            }
        }
        return { values: out, user: fromUser };
    }
    readonly property var notifications: notificationsConfigured.values
    // --- end spec 008 --------------------------------------------------------------------------------

    FileView {
        id: defaultsFile
        path: Qt.resolvedUrl("../config/defaults.json").toString().replace("file://", "")
        blockLoading: true
    }

    FileView {
        id: userFile
        path: root.userPath
        printErrors: false          // a missing user file is the normal case
        watchChanges: true
        onFileChanged: reload()
    }
}
