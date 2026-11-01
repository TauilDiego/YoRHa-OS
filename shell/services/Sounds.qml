pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QtQml.Models
import Quickshell.Io

// The interface sounds (spec 013, contracts/sounds.md, research S1).
//   play(event): "ok" when the sound started; "skipped: <why>" when a rule held it back (sounds off,
//   system muted, do-not-disturb, typing off, the 40 ms debounce, 4 at once); "error: …" for an
//   unknown event. Every call is kept in `last` (the newest 20, { event, t: Date.now(), played }) for
//   the tests' timing (`sounds dump`).
//
// Where the sounds are (decision of T042): `soundsDir`, the first of
//   1. $YORHA_OS_SOUNDS                     the lab, a test, an unusual install
//   2. /usr/share/yorha-os/sounds           the installed system
//   3. <shell>/../system/sounds             running from the repository (shell/ and system/ side by side)
// that has move.wav. lab/sync sends system/sounds/*.wav to ~/nier/system/sounds, so the third rule
// finds them on the lab's VMs (~/nier/ui is shell/) with no environment. The boot and login sounds
// don't come from here (the module installs its own copies).
//
// Rules:
//   - one SoundEffect pool per event (UiSound): 3 instances for move, change and osd, 1 for the rest;
//     40 ms debounce per event, at most 4 sounds at once;
//   - the user's folder (sound.folder): <folder>/<event>.wav, then .ogg. What is missing, or does not
//     open, plays ours, with one INFO line in the log;
//   - volume: sound.volume (0–100) is the SoundEffect's, over the system's (the stream goes through the
//     default sink, so its volume and its mute apply on their own; muted, nothing starts);
//   - sound.ui off silences all but the entry sound (sound.bootLogin);
//   - no typing sound (the owner's decision, 2026-11-01: none, not even as an option);
//   - notify obeys do-not-disturb and the held full screen (NotifyStore.held); a critical one shows
//     through them, so it sounds;
//   - sound.json (data-model.md) is written 500 ms after the sink's volume or mute, uiVolume or
//     bootLogin change: the boot service reads it.
Singleton {
    id: root

    // Event → our file in system/sounds/ (data-model.md). Several events share a sound.
    readonly property var events: ({
        move: "move.wav",
        change: "move.wav",
        confirm: "confirm.wav",
        back: "back.wav",
        open: "open.wav",
        close: "close.wav",
        tab: "tab.wav",
        dialog: "dialog.wav",
        choiceOpen: "open.wav",
        choicePick: "confirm.wav",
        notify: "notify.wav",
        notifyCritical: "notify-critical.wav",
        osd: "move.wav",
        sessionStart: "session-start.wav"
    })
    // The sounds that repeat fast: three instances, and a new one cuts the last.
    readonly property var repeated: ["move", "change", "osd"]
    readonly property int maxAtOnce: 4

    property var last: []

    // --- where the files are -----------------------------------------------------------------------
    readonly property string envDir: Quickshell.env("YORHA_OS_SOUNDS") ?? ""
    readonly property string systemDir: "/usr/share/yorha-os/sounds"
    readonly property string repoDir: Quickshell.shellDir + "/../system/sounds"
    readonly property string soundsDir: envDir !== "" && envProbe.loaded ? envDir
        : systemProbe.loaded ? systemDir : repoProbe.loaded ? repoDir : ""
    FileView { id: envProbe; path: root.envDir !== "" ? root.envDir + "/move.wav" : ""; blockLoading: true; printErrors: false }
    FileView { id: systemProbe; path: root.systemDir + "/move.wav"; blockLoading: true; printErrors: false }
    FileView { id: repoProbe; path: root.repoDir + "/move.wav"; blockLoading: true; printErrors: false }

    // --- the user's folder -------------------------------------------------------------------------
    // "~/x" expanded; "" is ours.
    readonly property string folder: {
        const f = Settings.soundFolder.trim();
        return f.startsWith("~/") ? Quickshell.env("HOME") + f.slice(1) : f;
    }
    // event → the file (a path) found in the folder; the INFO line goes out once per folder.
    property var custom: ({})
    property string listedFolder: ""

    onFolderChanged: scan()
    function scan(): void {
        custom = {};
        listedFolder = "";
        if (folder === "")
            return;
        lister.command = ["ls", "-1", "--", folder];
        lister.running = true;
    }
    function applyListing(text: string): void {
        const names = text.split("\n").filter(n => n !== "");
        const found = {};
        const missing = [];
        for (const ev of Object.keys(events)) {
            const f = names.includes(ev + ".wav") ? ev + ".wav" : names.includes(ev + ".ogg") ? ev + ".ogg" : "";
            if (f !== "")
                found[ev] = folder + "/" + f;
            else
                missing.push(ev);
        }
        custom = found;
        listedFolder = folder;
        console.info(`sounds: folder ${folder}: ${Object.keys(found).length} of ${Object.keys(events).length} events found`
            + (missing.length ? `, ours for ${missing.join(", ")}` : ""));
    }
    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: root.applyListing(text)
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.custom = {};
                console.info(`sounds: cannot read the folder ${root.folder} (ls exit ${code}), using ours`);
            }
        }
    }

    // --- the pools ---------------------------------------------------------------------------------
    readonly property real effectVolume: Math.max(0, Math.min(1, Settings.soundVolume / 100))
    property var pools: ({})

    Instantiator {
        model: Object.keys(root.events)
        delegate: UiSound {
            required property string modelData
            name: modelData
            fallback: root.soundsDir !== "" ? "file://" + root.soundsDir + "/" + root.events[modelData] : ""
            custom: root.custom[modelData] ? "file://" + root.custom[modelData] : ""
            volume: root.effectVolume
            copies: root.repeated.includes(modelData) ? 3 : 1
            cutting: copies > 1
            debounceMs: 40
            onFailed: (n, file) => console.info(`sounds: ${file} does not open as a sound, using ours for ${n}`)
        }
        onObjectAdded: (index, object) => {
            const u = object as UiSound;
            const p = Object.assign({}, root.pools);
            p[u.name] = u;
            root.pools = p;
        }
    }

    function playingNow(): int {
        let n = 0;
        for (const k of Object.keys(pools))
            n += pools[k].playingCount;
        return n;
    }

    readonly property bool systemMuted: Audio.sink?.audio?.muted === true

    // Why `event` must not sound now, or "".
    function heldBack(event: string): string {
        if (event === "sessionStart")
            return Settings.soundBootLogin ? "" : "boot and login sounds off";
        if (!Settings.soundUi)
            return "sounds off";
        if (event === "notify" && NotifyStore.held)
            return "do not disturb";
        return "";
    }

    function play(event: string): string {
        if (!Object.prototype.hasOwnProperty.call(events, event))
            return `error: unknown event ${event}`;
        let why = heldBack(event);
        if (why === "" && systemMuted)
            why = "system muted";
        if (why === "" && playingNow() >= maxAtOnce)
            why = `${maxAtOnce} at once`;
        const ui = why === "" ? pools[event] : null;
        if (why === "" && !ui)
            why = "not loaded";
        if (why === "" && !ui.trigger())
            why = "debounce";
        last = last.concat([{ event: event, t: Date.now(), played: why === "" }]).slice(-20);
        return why === "" ? "ok" : `skipped: ${why}`;
    }

    function dump(): var {
        return {
            enabled: Settings.soundUi,
            volume: Settings.soundVolume,
            folder: Settings.soundFolder,
            overrides: Object.keys(custom).filter(ev => pools[ev]?.useCustom === true),
            dir: soundsDir,
            bootLogin: Settings.soundBootLogin,
            systemMuted: systemMuted,
            last: last
        };
    }

    // --- the entry sound, once per login (research S5) -------------------------------------------
    // mkdir is atomic: the first shell of this login makes the lock in $XDG_RUNTIME_DIR (gone with
    // the session) and plays; a restarted shell finds it and stays quiet.
    function sessionStart(): void {
        if (started || Fixtures.active)
            return;
        started = true;
        lock.running = true;
    }
    property bool started: false
    Process {
        id: lock
        command: ["sh", "-c", "d=\"${XDG_RUNTIME_DIR:-/tmp}/yorha-os\"; mkdir -p \"$d\" && mkdir \"$d/session-start-played\" 2>/dev/null"]
        onExited: (code, status) => {
            if (code === 0)
                root.play("sessionStart");
        }
    }

    // --- sound.json (data-model.md) --------------------------------------------------------------
    readonly property string statePath: {
        const xdg = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state");
        return xdg + "/yorha-os/sound.json";
    }
    readonly property var sinkAudio: Audio.sink?.audio ?? null
    readonly property bool stateKnown: sinkAudio !== null && isFinite(sinkAudio.volume)
    readonly property string stateKey: stateKnown
        ? `${Math.round(sinkAudio.volume * 100)}|${sinkAudio.muted}|${Settings.soundVolume}|${Settings.soundBootLogin}` : ""
    onStateKeyChanged: if (stateKey !== "" && !Fixtures.active) saveTimer.restart()
    Timer {
        id: saveTimer
        interval: 500
        onTriggered: root.writeState()
    }
    property bool fileReady: false
    function stamp(): string {
        const d = new Date();
        const p = (n, w) => String(n).padStart(w ?? 2, "0");
        const off = -d.getTimezoneOffset();
        const a = Math.abs(off);
        return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
            + `${off < 0 ? "-" : "+"}${p(Math.floor(a / 60))}:${p(a % 60)}`;
    }
    function writeState(): void {
        if (!stateKnown)
            return;
        if (!fileReady) {
            fileCreate.command = ["sh", "-c", "[ -e \"$1\" ] || install -D -m 644 /dev/null \"$1\"", "sh", statePath];
            fileCreate.running = true;
            return;
        }
        file.setText(JSON.stringify({
            volume: Math.round(sinkAudio.volume * 100) / 100,
            muted: sinkAudio.muted === true,
            uiVolume: Settings.soundVolume,
            bootLogin: Settings.soundBootLogin,
            updated: stamp()
        }) + "\n");
    }
    Process {
        id: fileCreate
        onExited: (code, status) => {
            root.fileReady = code === 0;
            if (root.fileReady)
                root.writeState();
            else
                console.info(`sounds: cannot create ${root.statePath} (exit ${code})`);
        }
    }
    FileView {
        id: file
        path: root.statePath
        atomicWrites: true
        printErrors: false
        blockLoading: true
        preload: false
    }
}
