import QtQuick
import QtMultimedia

// One interface sound (spec 013, contracts/sounds.md): `copies` SoundEffect instances taken in turn
// (3 for the sounds that repeat, so a new play never has to wait for the last one's tail), the
// 40 ms debounce, and the choice between the user's file and ours. Owned by the Sounds singleton.
//   custom   the user's file for this event ("" for none): played while it opens; if it doesn't
//            (corrupt, wrong format) failed(name, file) is emitted once and ours plays instead
//   fallback our file in system/sounds/
Item {
    id: root

    property string name
    property url fallback
    property url custom
    property real volume: 0.4
    property int copies: 1
    // Repeated sounds cut the one before (a new tick ends the last one) instead of piling up.
    property bool cutting: false
    property real debounceMs: 40
    // SoundEffect.Status's values (Qt 6: Null 0, Loading 1, Ready 2, Error 3), named here so the code
    // never reads the enum through the type: the CI's qmllint has no QtMultimedia and reported those
    // reads as unqualified (spec 015).
    readonly property int statusReady: 2
    readonly property int statusError: 3

    readonly property bool useCustom: custom.toString() !== "" && !customFailed
    readonly property url source: useCustom ? custom : fallback
    property bool customFailed: false
    property real lastAt: 0
    property int turn: 0
    property real pendingAt: 0

    readonly property var effects: copies >= 3 ? [e0, e1, e2] : [e0]
    readonly property int playingCount: {
        let n = 0;
        for (const e of effects)
            if (e.playing)
                n++;
        return n;
    }
    // The state of the first instance (every one has the same source).
    readonly property int status: e0.status

    signal failed(string name, string file)

    onCustomChanged: customFailed = false

    // Start the sound: false when the debounce swallows it. Before the file has loaded (the first
    // play after a start or a change of source) it plays as soon as it is ready, if that is soon.
    function trigger(): bool {
        const now = Date.now();
        if (now - lastAt < debounceMs)
            return false;
        lastAt = now;
        const e = effects[turn % effects.length];
        if (e.status === root.statusReady) {
            if (cutting && effects.length > 1)
                effects[(turn + effects.length - 1) % effects.length].stop();
            e.play();
            turn++;
        } else {
            pendingAt = now;
        }
        return true;
    }

    function onState(e: var): void {
        if (e.status === root.statusError && useCustom) {
            customFailed = true;
            failed(name, custom.toString().replace("file://", ""));
        } else if (e.status === root.statusReady && pendingAt > 0) {
            if (Date.now() - pendingAt < 600 && e === effects[turn % effects.length])
                e.play();
            pendingAt = 0;
            turn++;
        }
    }

    SoundEffect {
        id: e0
        source: root.source
        volume: root.volume
        onStatusChanged: root.onState(e0)
    }
    SoundEffect {
        id: e1
        source: root.copies >= 3 ? root.source : ""
        volume: root.volume
        onStatusChanged: root.onState(e1)
    }
    SoundEffect {
        id: e2
        source: root.copies >= 3 ? root.source : ""
        volume: root.volume
        onStatusChanged: root.onState(e2)
    }
}
