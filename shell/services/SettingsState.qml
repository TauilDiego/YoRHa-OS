pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Saved settings ("salvar sempre", the owner's decision of 2026-10-27): one keyed store for every
// value a menu lets the user change: System Settings now, the pause menu (spec 007) and the
// notifications (spec 008) later. It lives in $XDG_STATE_HOME/rien-os/settings.json, never in
// ~/.config (constitution III): read once at start, written 250 ms after the last change, in one
// atomic write. It sits on top of the base (config/defaults.json overridden by shell.json).
//   Keys are "<owner>.<id>": "settings.<category>.<option>" for the settings pop-up's catalog,
//   "shell.<key>" for the shell settings it changes live (Settings), "<menu>.<id>" for the next
//   menus. Values are plain JSON; each owner validates what it reads back.
// With fixtures active the file is neither read nor written: the store lives in memory only, so
// tests don't depend on the VM's state and don't change it (contracts: specs/004-wallpaper-system/
// contracts/settings-state.md).
Singleton {
    id: root

    readonly property bool persisted: !Fixtures.active
    readonly property string path: {
        const xdg = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state");
        return xdg + "/rien-os/settings.json";
    }

    property var values: ({})                  // key → value

    function has(key: string): bool {
        return Object.prototype.hasOwnProperty.call(values, key);
    }
    function get(key: string, fallback: var): var {
        return has(key) ? values[key] : fallback;
    }
    function set(key: string, value: var): void {
        if (has(key) && JSON.stringify(values[key]) === JSON.stringify(value))
            return;
        const next = Object.assign({}, values);
        next[key] = value;
        values = next;
        changed();
    }
    function remove(key: string): void {
        if (!has(key))
            return;
        const next = Object.assign({}, values);
        delete next[key];
        values = next;
        changed();
    }
    // Every key that starts with `prefix` ("settings." = all of the settings pop-up's values).
    function clear(prefix: string): void {
        const next = {};
        let gone = false;
        for (const k of Object.keys(values)) {
            if (k.startsWith(prefix))
                gone = true;
            else
                next[k] = values[k];
        }
        if (!gone)
            return;
        values = next;
        changed();
    }

    // --- file ----------------------------------------------------------------------------------
    property string badState: ""
    function load(): void {
        if (!persisted) {
            values = {};
            return;
        }
        file.reload();
        const text = file.text();
        if (!text) {
            values = {};
            return;
        }
        try {
            const d = JSON.parse(text);
            if (d && typeof d.values === "object" && d.values !== null && !Array.isArray(d.values)) {
                values = d.values;
                return;
            }
        } catch (e) {
        }
        if (badState !== text) {
            badState = text;
            console.info(`settings: ${path} is not a valid state file, starting from the defaults`);
        }
        values = {};
    }

    function changed(): void {
        if (persisted)
            saveSoon.restart();
    }

    function save(): void {
        if (persisted)
            file.setText(JSON.stringify({ version: 1, values: values }, null, 2) + "\n");
    }

    Timer {
        id: saveSoon
        interval: 250
        onTriggered: root.save()
    }

    // setText() writes atomically and creates the folder when needed.
    FileView {
        id: file
        path: root.path
        blockLoading: true
        printErrors: false          // no file yet is the normal first run
        atomicWrites: true
    }

    onPersistedChanged: {
        saveSoon.stop();
        load();
    }
    Component.onCompleted: load()
}
