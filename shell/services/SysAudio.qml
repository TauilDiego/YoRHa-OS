pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../strings"

// spec 019 (contracts/system-provider.md, research R6): the sound rows, read from and written to
// PipeWire, with no saved copy (FR-017). The keys are output, volume, mute and mic. A row asks here and
// PipeWire answers: what the keys and `wpctl` change shows by itself (FR-018), and WirePlumber is what
// keeps the chosen output (D4). The "audioDevices" fixture comes first and only changes memory; with
// any other fixture this still reads the system, but never writes to it (FR-009).
Singleton {
    id: root

    // --- the fixture: a copy, so a write changes it in memory -------------------------------------
    readonly property var fixture: Fixtures.has("audioDevices") ? (Fixtures.get("audioDevices") ?? ({})) : null
    property var fx: null
    onFixtureChanged: fx = root.copied(fixture)
    Component.onCompleted: fx = root.copied(fixture)

    function copied(f: var): var {
        return f ? { sinks: (f.sinks ?? []).map(x => Object.assign({}, x)), sources: (f.sources ?? []).map(x => Object.assign({}, x)),
            defaultSink: f.defaultSink ?? null, defaultSource: f.defaultSource ?? null } : null;
    }
    readonly property var fxSink: fx ? (fx.sinks.find(x => x.id === fx.defaultSink) ?? null) : null
    readonly property var fxSource: fx ? (fx.sources.find(x => x.id === fx.defaultSource) ?? null) : null

    // --- PipeWire -----------------------------------------------------------------------------------
    // The outputs and inputs of the machine: no app streams, no node without volume, and not WirePlumber's
    // "Dummy Output" (auto_null), which plays nothing (R6).
    readonly property var sinkNodes: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio !== null && n.name !== "auto_null")
    readonly property var sourceNodes: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio !== null)
    readonly property PwNode sink: sinkNodes.includes(Pipewire.defaultAudioSink) ? Pipewire.defaultAudioSink : null
    readonly property PwNode source: sourceNodes.includes(Pipewire.defaultAudioSource) ? Pipewire.defaultAudioSource : null
    PwObjectTracker {
        objects: root.fx ? [] : root.sinkNodes.concat(root.sourceNodes)
    }

    // --- the optimistic write (the contract): what was asked shows until PipeWire says the same, for 300 ms
    // at most. Held keys move from the last position asked, and each write replaces the one before
    // (nothing queues). `failed`: a key the system didn't follow, until it next changes.
    property var asked: ({})
    property var failed: ({})

    function has(map: var, key: string): bool {
        return Object.prototype.hasOwnProperty.call(map, key);
    }
    function without(map: var, key: string): var {
        const out = Object.assign({}, map);
        delete out[key];
        return out;
    }
    // The system changed `key`: confirms what was asked, and a refused write is old news.
    function seen(key: string): void {
        if (has(failed, key))
            failed = without(failed, key);
        if (has(asked, key) && real(key) === asked[key])
            asked = without(asked, key);
    }
    Timer {
        id: giveUp
        interval: 300
        onTriggered: {
            const refused = {};
            for (const key of Object.keys(root.asked))
                if (root.real(key) !== root.asked[key])
                    refused[key] = true;
            root.asked = {};
            root.failed = Object.assign({}, root.failed, refused);
        }
    }
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged(): void {
            root.seen("volume");
        }
        function onMutedChanged(): void {
            root.seen("mute");
        }
    }
    Connections {
        target: root.source?.audio ?? null
        function onVolumeChanged(): void {
            root.seen("mic");
        }
        function onMutedChanged(): void {
            root.seen("mic");
        }
    }
    // Another output: its own volume and mute, and nothing asked of the old one still shows.
    onSinkChanged: {
        asked = without(without(asked, "volume"), "mute");
        failed = without(without(failed, "volume"), "mute");
        seen("output");
    }
    onSourceChanged: {
        asked = without(asked, "mic");
        failed = without(failed, "mic");
    }

    function percent(node: var): int {
        return Math.round((node?.audio?.volume ?? 0) * 100);
    }
    // What the system (or the fixture) says now.
    function real(key: string): var {
        switch (key) {
        case "output":
            return fx ? String(fx.defaultSink ?? "") : String(sink?.name ?? "");
        case "volume":
            return fx ? Number(fxSink?.volume ?? 0) : percent(sink);
        case "mute":
            return fx ? fxSink?.muted === true : sink?.audio?.muted === true;
        case "mic":
            return fx ? Number(fxSource?.volume ?? 0) : percent(source);
        }
        return null;
    }

    // --- the provider's interface ---------------------------------------------------------------
    function levelsOf(key: string): var {
        if (key !== "output")
            return [];
        return fx ? fx.sinks.map(x => String(x.id)) : sinkNodes.map(n => String(n.name));
    }
    function labelsOf(key: string): var {
        if (key !== "output")
            return [];
        return fx ? fx.sinks.map(x => String(x.label)) : sinkNodes.map(n => String(n.description || n.nickname || n.name));
    }
    function levelOf(key: string): var {
        return has(asked, key) ? asked[key] : real(key);
    }
    function setLevel(key: string, level: var): void {
        if (fx) {
            remember(key, level);
            return;
        }
        if (Fixtures.active || !write(key, level))
            return;
        failed = without(failed, key);
        asked = Object.assign({}, asked, { [key]: level });
        giveUp.restart();
        seen(key);
    }
    // Asks PipeWire. False when there is nothing to ask (the row is dimmed, or the output is gone).
    function write(key: string, level: var): bool {
        switch (key) {
        case "output": {
            const node = sinkNodes.find(n => n.name === level);
            if (node)
                Pipewire.preferredDefaultAudioSink = node;
            return node !== undefined;
        }
        case "volume":
            if (available(key))
                sink.audio.volume = Number(level) / 100;
            return available(key);
        case "mute":
            if (available(key))
                sink.audio.muted = level === true;
            return available(key);
        case "mic":
            if (available(key))
                source.audio.volume = Number(level) / 100;
            return available(key);
        }
        return false;
    }
    // With the fixture, a write changes the copy in memory.
    function remember(key: string, level: var): void {
        const next = copied(fx);
        const row = key === "mic" ? next.sources.find(x => x.id === next.defaultSource) : next.sinks.find(x => x.id === next.defaultSink);
        if (key === "output")
            next.defaultSink = String(level);
        else if (key === "volume" && row)
            row.volume = Number(level);
        else if (key === "mute" && row)
            row.muted = level === true;
        else if (key === "mic" && row)
            row.volume = Number(level);
        fx = next;
    }
    function available(key: string): bool {
        switch (key) {
        case "output":
            return levelsOf(key).length > 0;
        case "volume":
        case "mute":
            return fx ? fxSink !== null : (sink?.ready ?? false);
        case "mic":
            return fx ? fxSource !== null : (source?.ready ?? false);
        }
        return false;
    }
    function reason(key: string): string {
        if (available(key))
            return "";
        return key === "mic" ? Strings.settings.sys.noMic : Strings.settings.sys.noOutput;
    }
    function rangeOf(key: string): var {
        return { min: 0, max: 100 };
    }
    // A refused write (FR-002), or the microphone muted by its key.
    function note(key: string): string {
        if (has(failed, key))
            return Strings.settings.sys.soundWriteFailed;
        const micMuted = fx ? fxSource?.muted === true : source?.audio?.muted === true;
        return key === "mic" && available(key) && micMuted ? Strings.settings.sys.micMuted : "";
    }
}
