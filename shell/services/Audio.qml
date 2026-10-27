pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../strings"

// Volume Reading of the default PipeWire sink (research R2), or the "volume" fixture
// ({ percent, muted }). Muted → value 0 and extra "muted"; no sink → value 0.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink

    readonly property var vol: {
        let value = 0;
        let muted = false;
        if (Fixtures.has("volume")) {
            const f = Fixtures.get("volume") ?? {};
            value = Number(f.percent) / 100;
            muted = f.muted === true;
        } else {
            const a = sink?.audio ?? null;
            value = a?.volume ?? 0;
            muted = a?.muted ?? false;
        }
        return {
            key: "vol",
            label: Strings.vol,
            value: muted || !isFinite(value) ? 0 : Math.max(0, Math.min(1, value)),
            critical: false,
            extra: muted ? "muted" : "none",
            available: true
        };
    }

    // Keeps the sink's audio properties bound (PipeWire only tracks objects someone holds).
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
