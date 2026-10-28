pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings: managed defaults (config/defaults.json) overridden key by key by the user's
// $XDG_CONFIG_HOME/rien-os/shell.json. Updates never touch the user file (constitution III).
Singleton {
    id: root

    readonly property real uiScale: valid(merged.uiScale, 0.5, 3.0, "uiScale") ? merged.uiScale : defaults.uiScale
    readonly property int barHeight: Math.round(Math.max(28, Math.min(96, Number(merged.barHeight) || defaults.barHeight)))
    readonly property bool vignette: typeof merged.vignette === "boolean" ? merged.vignette : defaults.vignette
    readonly property bool wallpaperMotion: typeof merged.wallpaperMotion === "boolean" ? merged.wallpaperMotion : defaults.wallpaperMotion
    // Reduced motion: fades, the selector blink and wallpaper transitions become instant.
    readonly property bool reduceMotion: typeof merged.reduceMotion === "boolean" ? merged.reduceMotion : defaults.reduceMotion

    readonly property var defaults: parse(defaultsFile.text(), "defaults.json") ?? ({ uiScale: 1.0, barHeight: 68, vignette: true, wallpaperMotion: true, reduceMotion: false, barContrast: "normal" })
    readonly property var user: userFile.loaded ? (parse(userFile.text(), userFile.path) ?? ({})) : ({})
    readonly property var merged: Object.assign({}, defaults, user)

    readonly property string userPath: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config");
        return xdg + "/rien-os/shell.json";
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
    // catalog is a choice over these values, in this order.
    function levelsOf(key: string): var {
        return key === "barContrast" ? barContrastLevels : [];
    }
    function levelOf(key: string): string {
        return key === "barContrast" ? barContrast : "";
    }
    // Save `level` for `key` (SettingsState, "shell.<key>"); "" goes back to shell.json / defaults.
    function setLevel(key: string, level: string): void {
        if (levelsOf(key).includes(level))
            SettingsState.set("shell." + key, level);
        else
            SettingsState.remove("shell." + key);
    }
    // --- end 004 acabamento ------------------------------------------------------------------------

    // --- spec 008: the notifications' options (FR-039, FR-040) ---------------------------------------
    // The project's defaults (defaults.json) overridden key by key by the user's shell.json, each value
    // checked against its options. NotifyPrefs puts the saved choices (SettingsState) on top.
    readonly property var notificationChoices: ({
        position: ["corner", "top", "subtitle"],
        osdPosition: ["bottom", "top"],
        voice: ["relay", "rienos", "system"],
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
