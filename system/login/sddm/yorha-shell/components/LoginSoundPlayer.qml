import QtQuick
import QtMultimedia

// The login's SoundEffects (spec 013, FR-029). Its own file, loaded by LoginSounds through a Loader:
// without QtMultimedia this file fails to load and the login simply stays quiet, nothing else breaks.
// The files are copies of system/sounds/{intro,move,confirm,error,close}.wav (our own sounds).
// The greeter's PipeWire starts with the first client (this one) and WirePlumber needs a second or
// two to bring the card's sink up: until then Qt has only a dummy output, the effects go to Error
// ("playback of this format is not supported") and come back to Ready when the card shows (lab,
// teste-011). So a sound asked for before its effect is Ready waits for it (the intro, at most 4 s; any
// other sound is dropped: a late tick on the list is worse than none).
Item {
    id: root

    property real volume: 0.09
    property string queued: ""
    property real queuedAt: 0

    function play(name: string): void {
        const e = effects[name];
        if (!e)
            return;
        if (e.status === SoundEffect.Ready) {
            e.play();
        } else if (name === "intro") {
            queued = name;
            queuedAt = Date.now();
        }
    }

    function ready(name: string): void {
        if (queued === name && Date.now() - queuedAt < 4000) {
            queued = "";
            effects[name].play();
            console.log("yorha-login: intro sound started " + (Date.now() - queuedAt) + " ms late (the card was not up yet)");
        }
    }

    readonly property var effects: ({ intro: intro, move: move, confirm: confirm, error: error, close: close })

    SoundEffect { id: intro; source: Qt.resolvedUrl("../assets/sounds/intro.wav"); volume: root.volume; onStatusChanged: if (status === SoundEffect.Ready) root.ready("intro") }
    SoundEffect { id: move; source: Qt.resolvedUrl("../assets/sounds/move.wav"); volume: root.volume }
    SoundEffect { id: confirm; source: Qt.resolvedUrl("../assets/sounds/confirm.wav"); volume: root.volume }
    SoundEffect { id: error; source: Qt.resolvedUrl("../assets/sounds/error.wav"); volume: root.volume }
    SoundEffect { id: close; source: Qt.resolvedUrl("../assets/sounds/close.wav"); volume: root.volume }
}
