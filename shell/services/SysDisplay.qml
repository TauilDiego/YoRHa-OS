pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../strings"

// spec 019 (contracts/system-provider.md): the Display rows.
// resolution, refresh, scale: read-only text of the monitor in focus (D5, FR-023), through the adapter;
// its name goes on the card. What raises no event is read again while Display is on screen (R5).
// brightness: the % that Osd.qml reads, written with brightnessctl to the same device (R7, FR-020 to
// FR-022). The "brightness" fixture comes first: null = no backlight, { percent, device, tool };
// tool false = no brightnessctl. Under it a write stays in memory, and under any fixture nothing is
// written to the system (FR-009). Nothing is saved (FR-017).
Singleton {
    id: root

    // --- the monitor in focus ---------------------------------------------------------------------
    readonly property var monitor: Compositor.focusedMonitorInfo
    // "Hz" and "×" are units, not words, so they stay here.
    function monitorText(key: string): string {
        const m = monitor;
        if (!m)
            return Strings.settings.sys.empty;
        switch (key) {
        case "resolution":
            return Strings.pause.sizeValue.arg(m.width).arg(m.height);
        case "refresh":
            return `${Number(m.refreshRate.toFixed(2))} Hz`;      // 74.998 → 75 Hz; 59.951 → 59.95 Hz
        case "scale":
            return `${m.scale.toFixed(2)}×`;
        }
        return "";
    }
    function isMonitorKey(key: string): bool {
        return key === "resolution" || key === "refresh" || key === "scale";
    }

    // No event for some changes (a mode set by `hyprctl eval`), so with Display on screen they are read
    // again, in time to show within 1 s (SC-003). The backend asks nothing in its wait after a reload
    // (sondagem.md), so this can't land there.
    Timer {
        interval: 800
        repeat: true
        triggeredOnStart: true
        running: SettingsModel.watching === "display" && !Fixtures.has("monitors") && Compositor.supports("monitorInfo")
        onTriggered: Compositor.refreshFocusedMonitor()
    }

    // --- the backlight ----------------------------------------------------------------------------
    readonly property bool fixed: Fixtures.has("brightness")
    readonly property var fixture: fixed ? (Fixtures.get("brightness") ?? null) : null
    readonly property bool hasBacklight: fixed ? fixture !== null : Osd.brightnessAvailable
    readonly property bool hasTool: fixed ? fixture?.tool !== false : toolFound
    property bool toolFound: false
    property int written: -1                     // under the fixture: what a write left in memory
    readonly property int realPercent: fixed ? (written >= 0 ? written : Number(fixture?.percent ?? 0)) : Osd.brightnessPercent
    property int asked: -1                       // what the row shows until the system answers (300 ms)
    property int waiting: -1                     // the last position asked while a write runs
    property string failNote: ""

    function write(percent: int): void {
        writer.command = ["brightnessctl", `--device=${Osd.backlightDevice}`, "set", `${percent}%`];
        writer.running = true;
    }
    Process {
        id: writer
        onExited: code => {
            if (root.waiting >= 0) {             // held key: only the last position counts
                const next = root.waiting;
                root.waiting = -1;
                root.write(next);
                return;
            }
            Osd.readBrightness();
            if (code !== 0) {
                root.asked = -1;
                root.failNote = Strings.settings.sys.brightnessWriteFailed;
            }
        }
    }
    Timer {
        id: askedHold
        interval: 300
        onTriggered: {
            if (writer.running || root.waiting >= 0)
                restart();
            else
                root.asked = -1;
        }
    }
    Connections {
        target: Osd
        function onBrightnessPercentChanged(): void {
            if (Osd.brightnessPercent === root.asked && !writer.running && root.waiting < 0)
                root.asked = -1;
        }
    }
    Process {
        running: true
        command: ["sh", "-c", "command -v brightnessctl"]
        onExited: code => root.toolFound = code === 0
    }
    Connections {
        target: Fixtures
        function onDataChanged(): void {
            root.written = -1;
            root.asked = -1;
            root.waiting = -1;
            root.failNote = "";
        }
    }

    // --- the provider -----------------------------------------------------------------------------
    function levelsOf(key: string): var {
        return [];
    }
    function labelsOf(key: string): var {
        return [];
    }
    function levelOf(key: string): var {
        if (isMonitorKey(key))
            return monitorText(key);
        if (key !== "brightness" || !hasBacklight)
            return null;
        return asked >= 0 ? asked : realPercent >= 0 ? realPercent : null;
    }
    function setLevel(key: string, level: var): void {
        if (key !== "brightness" || !available(key))
            return;
        const r = rangeOf(key);
        const percent = Math.max(r.min, Math.min(r.max, Math.round(Number(level)) || 0));
        failNote = "";
        if (fixed) {
            written = percent;
            return;
        }
        if (Fixtures.active)
            return;
        asked = percent;
        askedHold.restart();
        if (writer.running)
            waiting = percent;
        else
            write(percent);
    }
    function available(key: string): bool {
        return isMonitorKey(key) || (key === "brightness" && hasBacklight && hasTool);
    }
    function reason(key: string): string {
        if (available(key))
            return "";
        return hasBacklight ? Strings.settings.sys.noBrightnessctl : Strings.settings.sys.noBacklight;
    }
    function rangeOf(key: string): var {
        // Not below 5% by the row, so the screen doesn't go dark on a click (FR-022). With no backlight
        // the track stays empty.
        return key === "brightness" && hasBacklight ? { min: 5, max: 100 } : { min: 0, max: 100 };
    }
    function note(key: string): string {
        return key === "brightness" ? failNote : "";
    }
    function metaOf(key: string): var {
        return isMonitorKey(key) && monitor ? [{ label: Strings.wallpaper.monitor.toUpperCase(), value: monitor.name }] : [];
    }
}
