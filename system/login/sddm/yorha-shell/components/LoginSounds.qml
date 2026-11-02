import QtQuick

// The login's sounds (spec 013, FR-029, contracts/boot-sound.md): play("intro" | "move" | "confirm" |
// "error" | "close"). Nothing is created until /run/yorha-shell/sound.state exists: the boot sound's
// script writes it AFTER the sound ends, and an audio server opened by the greeter while the card is
// still held makes the card's node vanish (sondagem S4). It waits for it at most 2 s, then plays at
// 30%. The file also says the volume (level, in %; the sound's gain follows the level squared, like
// the boot sound's files) and whether the user wants these sounds at all (enabled).
// Without QtMultimedia or an audio server the login stays quiet and shows nothing.
Item {
    id: root

    property bool wanted: true           // the theme's `sounds=on|off`
    property bool primary: true          // one screen plays, not every one the SDDM loads
    property bool ready: false
    property real volume: 0.09
    property string pending: ""          // the intro asked for before the state file came
    property real since: Date.now()

    readonly property bool active: wanted && primary

    function readState(): string {
        try {
            const x = new XMLHttpRequest();
            x.open("GET", "file:///run/yorha-shell/sound.state", false);
            x.send(null);
            return x.responseText ?? "";
        } catch (e) {
            return "";
        }
    }

    function play(name: string): void {
        if (!active)
            return;
        if (!ready) {
            if (name === "intro")
                pending = name;
            return;
        }
        if (player.item)
            player.item.play(name);
    }

    function settle(level: int, enabled: bool): void {
        ready = true;
        if (!enabled) {
            wanted = false;
            return;
        }
        volume = Math.pow(Math.max(0, Math.min(100, level)) / 100, 2);
        player.active = true;
    }

    function poll(): void {
        const t = readState().trim();
        if (t !== "") {
            let level = 30, enabled = true;
            try {
                const j = JSON.parse(t);
                if (Number.isFinite(j.level))
                    level = j.level;
                if (j.enabled === false)
                    enabled = false;
            } catch (e) {
                console.log("yorha-login: sound.state is not valid, using 30%");
            }
            settle(level, enabled);
        } else if (Date.now() - since > 2000) {
            settle(30, true);
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: root.active && !root.ready
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Loader {
        id: player
        active: false
        source: "LoginSoundPlayer.qml"
        onLoaded: {
            item.volume = Qt.binding(() => root.volume);
            if (root.pending !== "") {
                const p = root.pending;
                root.pending = "";
                item.play(p);
            }
        }
        onStatusChanged: if (status === Loader.Error) console.log("yorha-login: no sound (QtMultimedia missing?)")
    }
}
