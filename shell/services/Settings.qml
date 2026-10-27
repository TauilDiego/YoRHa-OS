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

    readonly property var defaults: parse(defaultsFile.text(), "defaults.json") ?? ({ uiScale: 1.0, barHeight: 68, vignette: true, wallpaperMotion: true, reduceMotion: false })
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
