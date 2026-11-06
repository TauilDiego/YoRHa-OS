pragma Singleton

import QtQuick
import Quickshell
import "../strings"

// spec 019 (contracts/system-provider.md): the keyboard rows Caps Lock, Repeat delay, Repeat rate and
// Shortcuts. They read Compositor.configValues, what the compositor really has (the "input" fixture
// goes in there too). A person's change goes to input.* in SettingsState and FileWins applies it;
// FileWins alone decides what stays after a reload (contracts/file-rule.md). A row nobody changed
// saves nothing and applies nothing (FR-025).
Singleton {
    id: root

    // Each row's key in SettingsState.
    readonly property var savedKeys: ({ delay: "input.repeatDelay", rate: "input.repeatRate", caps: "input.capsRule" })
    // Research R3. A delay of the config off this list joins it while in use.
    readonly property var delayLevels: [200, 300, 400, 600]
    readonly property int rateMin: 5                 // FR-028: a repeat rate of 0 turns repeating off
    readonly property int rateMax: 100
    readonly property var capsRules: ["", "caps:escape", "ctrl:nocaps"]
    // Another rule of the person's for the key: exists only while it is the one in use.
    readonly property string capsCustom: "custom"
    readonly property var labels: Strings.settings.sys

    readonly property bool fixed: Fixtures.has("input")
    property var written: ({})                       // the "input" fixture: key → what a write left in memory
    readonly property var values: Compositor.configValues

    // A write the compositor refused: which rows say so, until a write goes through.
    property var failed: ({})
    // What the writes under way replaced, to put back if they are refused: saved key → the saved value.
    property var attempts: ({})

    function has(map: var, key: string): bool {
        return Object.prototype.hasOwnProperty.call(map, key);
    }

    function levelsOf(key: string): var {
        if (!values)
            return [];                                   // not read yet: nothing to claim
        const level = levelOf(key);
        if (key === "delay")
            return delayLevels.includes(level) ? delayLevels : delayLevels.concat([level]).sort((a, b) => a - b);
        if (key === "caps")
            return level === capsCustom ? capsRules.concat([capsCustom]) : capsRules;
        return [];
    }
    function labelsOf(key: string): var {
        if (key === "delay")
            return levelsOf(key).map(ms => labels.msUnit.arg(ms));
        if (key === "caps")
            return levelsOf(key).map(rule => capsLabel(rule));
        return [];
    }
    function capsLabel(rule: string): string {
        switch (rule) {
        case "":
            return labels.capsLock;
        case "caps:escape":
            return labels.capsEscape;
        case "ctrl:nocaps":
            return labels.capsControl;
        }
        return labels.custom;
    }
    function levelOf(key: string): var {
        if (has(written, key))
            return written[key];
        if (!values)
            return null;
        switch (key) {
        case "delay":
            return values.repeatDelay;
        case "rate":
            return values.repeatRate;
        case "caps": {
            const part = FileWins.capsPart(values.kbOptions);
            return capsRules.includes(part) ? part : capsCustom;
        }
        }
        return null;
    }

    function validLevel(key: string, level: var): bool {
        switch (key) {
        case "delay":
            return levelsOf(key).includes(level);
        case "rate":
            // Above the top (the person's config) only a step down is a move (research R3).
            return Number.isInteger(level) && level >= rateMin && (level <= rateMax || level < levelOf(key));
        case "caps":
            return capsRules.includes(level);            // choosing Custom does nothing (research R3)
        }
        return false;
    }
    function setLevel(key: string, level: var): void {
        // The end of a list, or a click on the value in use: the person changed nothing (FR-025).
        if (level === levelOf(key) || !validLevel(key, level))
            return;
        if (fixed) {
            written = Object.assign({}, written, { [key]: level });
            return;
        }
        if (Fixtures.active)
            return;
        const saved = savedKeys[key];
        if (!has(attempts, saved))
            attempts = Object.assign({}, attempts, { [saved]: SettingsState.get(saved, undefined) });
        SettingsState.set(saved, level);
        FileWins.applySaved();
    }

    function available(key: string): bool {
        return true;
    }
    function reason(key: string): string {
        return "";
    }
    function rangeOf(key: string): var {
        return { min: rateMin, max: rateMax };
    }
    function note(key: string): string {
        if (key === "shortcuts")
            return Compositor.shortcutModifier === "" ? labels.modifierUnknown : "";
        return failed[key] === true ? labels.compositorWriteFailed : "";
    }
    // Keyboard › Shortcuts (FR-030): the product's keys, with the modifier in use. "SUPER", with the
    // card's warning, if the compositor didn't say which one it is.
    function listOf(key: string): var {
        if (key !== "shortcuts")
            return [];
        const mod = Compositor.shortcutModifier || "SUPER";
        // A media key has no combination to learn: its name is the row (keys is "XF86AudioMute").
        return Compositor.shortcuts.map(s => {
            const name = labels.shortcutNames[s.id] ?? s.id;
            return s.usesMod ? `${mod}+${s.keys} · ${name}` : name;
        });
    }

    // FR-029: only what the product saved. The compositor keeps its value until the next reload or login.
    function resetSaved(): void {
        written = {};
        failed = {};
        attempts = {};
        SettingsState.patch({}, Object.values(savedKeys));
    }

    Connections {
        target: Compositor
        // FR-002: a refused value doesn't stay saved, or the next reload would try it again. The row
        // is back on the real value by itself: a write ends with a new read.
        function onConfigWriteDone(ok: bool, error: string): void {
            const tried = root.attempts;
            root.attempts = {};
            if (ok) {
                root.failed = {};
                return;
            }
            // Without a change of the person's, it was the reapply of what is saved: that stays.
            const out = {};
            const asked = Object.keys(tried).length > 0;
            for (const row of Object.keys(root.savedKeys)) {
                const saved = root.savedKeys[row];
                if (asked ? root.has(tried, saved) : SettingsState.has(saved))
                    out[row] = true;
            }
            root.failed = out;
            const sets = {}, removes = [];
            for (const saved of Object.keys(tried)) {
                if (tried[saved] === undefined)
                    removes.push(saved);
                else
                    sets[saved] = tried[saved];
            }
            SettingsState.patch(sets, removes);
        }
    }
    Connections {
        target: Fixtures
        function onDataChanged(): void {
            root.written = {};
        }
    }

    // Research R5: `hyprctl eval` from outside raises no event, so what's on screen is read again, only
    // while the category is open. Well under 1 s, so the row is there within the second (SC-003).
    Timer {
        interval: 500
        repeat: true
        running: SettingsModel.watching === "keyboard" && !Fixtures.active
        onTriggered: Compositor.readConfig("poll")
    }
}
