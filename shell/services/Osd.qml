pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../ds"

// The on-screen display of volume, microphone and brightness (spec 008 US5, FR-028–FR-030, R12).
// One at a time: a change while it shows updates it in place and restarts its time
// (Tokens.notify.osdHold after the last change). Sources, whatever made the change (keys, another
// app, a command):
//   volume and mute   the default PipeWire sink (the first value and a change of default node show
//                     nothing: only a change of the same node does);
//   microphone        the default source's mute (MIC ON / MIC OFF, no meter);
//   brightness        `udevadm monitor` on the backlight subsystem, then the sysfs values (the VM has
//                     no backlight: brightnessAvailable is false and only `notify osd` shows it).
// A menu that already shows the value suppresses its kind (SettingsPage, FR-029). It never enters
// the log. With fixtures: the "notifications.osd" fixture, frozen; live changes are ignored.
Singleton {
    id: root

    property var current: null                 // { kind, value, muted, meter, monitor } or null
    property real hideAt: 0
    property var suppressed: ({})              // kind → true
    property bool brightnessAvailable: false
    readonly property bool fixed: Fixtures.has("notifications")

    // "ok" or "error: …" (IPC `notify osd`, and the live sources).
    function show(kind: string, value: int, muted: bool): string {
        if (!["volume", "mic", "brightness"].includes(kind))
            return "error: kind is volume, mic or brightness";
        if (kind !== "mic" && value < 0)
            return "error: value must be 0 or more";
        current = {
            kind: kind,
            value: kind === "brightness" ? Math.min(100, value) : value,
            muted: muted,
            meter: kind !== "mic",
            monitor: Compositor.focusedMonitor
        };
        if (fixed) {
            hideTimer.stop();
            hideAt = 0;
        } else {
            hideAt = Date.now() + Tokens.notify.osdHold;
            hideTimer.restart();
        }
        return "ok";
    }
    function hide(): void {
        hideTimer.stop();
        current = null;
    }
    function suppress(kind: string, on: bool): void {
        const next = Object.assign({}, suppressed);
        if (on)
            next[kind] = true;
        else
            delete next[kind];
        suppressed = next;
    }
    function remaining(): var {
        return current && hideAt > 0 ? Math.max(0, Math.round(hideAt - Date.now())) : null;
    }
    // A live change: shown unless suppressed, fixtures, or not armed yet.
    function changed(kind: string, value: int, muted: bool): void {
        if (fixed || suppressed[kind])
            return;
        show(kind, value, muted);
    }

    Timer {
        id: hideTimer
        interval: Tokens.notify.osdHold
        onTriggered: root.current = null
    }

    function loadFixture(): void {
        const o = Fixtures.get("notifications")?.osd ?? null;
        hide();
        if (o && typeof o === "object")
            show(String(o.kind), Number(o.value) || 0, o.muted === true);
    }
    Connections {
        target: Fixtures
        function onDataChanged(): void {
            if (root.fixed)
                root.loadFixture();
            else
                root.hide();
        }
    }
    Component.onCompleted: if (fixed) loadFixture()

    // --- PipeWire (volume, mute, microphone) ----------------------------------------------------------
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n !== null)
    }
    // A node's first values (and a new default node) show nothing: armed a moment after it is ready.
    property bool sinkArmed: false
    property bool sourceArmed: false
    onSinkChanged: {
        sinkArmed = false;
        armSink.restart();
    }
    onSourceChanged: {
        sourceArmed = false;
        armSource.restart();
    }
    Timer {
        id: armSink
        interval: 600
        running: true
        onTriggered: root.sinkArmed = root.sink?.ready ?? false
    }
    Timer {
        id: armSource
        interval: 600
        running: true
        onTriggered: root.sourceArmed = root.source?.ready ?? false
    }
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged(): void {
            if (root.sinkArmed)
                root.changed("volume", Math.round(root.sink.audio.volume * 100), root.sink.audio.muted);
        }
        function onMutedChanged(): void {
            if (root.sinkArmed)
                root.changed("volume", Math.round(root.sink.audio.volume * 100), root.sink.audio.muted);
        }
    }
    Connections {
        target: root.sink
        function onReadyChanged(): void {
            root.sinkArmed = false;
            armSink.restart();
        }
    }
    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged(): void {
            if (root.sourceArmed)
                root.changed("mic", 0, root.source.audio.muted);
        }
    }
    Connections {
        target: root.source
        function onReadyChanged(): void {
            root.sourceArmed = false;
            armSource.restart();
        }
    }

    // --- brightness (R12): udev events, then sysfs -------------------------------------------------------
    property string backlight: ""              // /sys/class/backlight/<device>, or ""
    Process {
        id: findBacklight
        running: true
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -r \"$d/brightness\" ] && echo \"$d\" && break; done; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.backlight = text.trim();
                root.brightnessAvailable = root.backlight !== "";
                if (root.brightnessAvailable)
                    udev.running = true;
            }
        }
    }
    Process {
        id: udev
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes(" change "))
                    brightRead.restart();
            }
        }
    }
    // Several events of one key press come together: read once after them.
    Timer {
        id: brightRead
        interval: 30
        onTriggered: {
            brightFile.reload();
            maxFile.reload();
            const v = Number(brightFile.text()), m = Number(maxFile.text());
            if (m > 0)
                root.changed("brightness", Math.round(v / m * 100), false);
        }
    }
    FileView {
        id: brightFile
        path: root.backlight ? root.backlight + "/brightness" : ""
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: maxFile
        path: root.backlight ? root.backlight + "/max_brightness" : ""
        blockLoading: true
        printErrors: false
    }

    function dump(): var {
        return current ? Object.assign({}, current, { remaining: remaining(), box: null }) : null;
    }
}
