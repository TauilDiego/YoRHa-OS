import QtQuick
import QtMultimedia

// The login's SoundEffects (spec 013, FR-029). Its own file, loaded by LoginSounds through a Loader:
// without QtMultimedia this file fails to load and the login simply stays quiet, nothing else breaks.
// The files are copies of system/sounds/{intro,move,confirm,error,close}.wav (our own sounds).
Item {
    id: root

    property real volume: 0.09

    function play(name: string): void {
        const e = effects[name];
        if (e)
            e.play();
    }

    readonly property var effects: ({ intro: intro, move: move, confirm: confirm, error: error, close: close })

    SoundEffect { id: intro; source: Qt.resolvedUrl("../assets/sounds/intro.wav"); volume: root.volume }
    SoundEffect { id: move; source: Qt.resolvedUrl("../assets/sounds/move.wav"); volume: root.volume }
    SoundEffect { id: confirm; source: Qt.resolvedUrl("../assets/sounds/confirm.wav"); volume: root.volume }
    SoundEffect { id: error; source: Qt.resolvedUrl("../assets/sounds/error.wav"); volume: root.volume }
    SoundEffect { id: close; source: Qt.resolvedUrl("../assets/sounds/close.wav"); volume: root.volume }
}
