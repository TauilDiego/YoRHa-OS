pragma Singleton

import QtQuick
import Quickshell

// The interface sounds (spec 013, contracts/sounds.md). The foundation's part (T016): the events
// and the API the menus call, Sounds.play("move"); nothing plays yet. Front D (T042) fills in the
// playing (a pool of SoundEffect per sound, the 40 ms debounce, at most 4 at once), the user's
// sound folder, the volume over the system's, and the notifications' rules.
//   play(event): "ok", or "error: …" for an unknown event; every call is kept in `last` (the
//   newest 20, { event, t: Date.now() }) for the tests' timing (`sounds dump`).
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
        typing: "typing.wav",
        sessionStart: "session-start.wav"
    })

    property var last: []

    function play(event: string): string {
        if (!Object.prototype.hasOwnProperty.call(events, event))
            return `error: unknown event ${event}`;
        last = last.concat([{ event: event, t: Date.now() }]).slice(-20);
        return "ok";
    }

    function dump(): var {
        return {
            enabled: Settings.soundUi,
            volume: Settings.soundVolume,
            typing: Settings.soundTyping,
            folder: Settings.soundFolder,
            overrides: [],
            last: last
        };
    }
}
