pragma ComponentBehavior: Bound

import QtQuick
import "../ds"

// The system's name entering with the glitch (spec 011 FR-017, research R4; mockup v3.2 ".title"):
// "YoRHa-OS" scrambled on the dark, settling from the left in 16 steps of 50 ms. Each step shifts it
// sideways, skews it and sometimes dims it; a red and a cyan copy sit beside it (the color split).
// `dark` switches it to ink over the paper. start() plays it, stop() freezes it settled.
Item {
    id: root

    property real s: 1
    property string word: "YoRHa-OS"
    property bool dark: false

    readonly property string glyphs: "ЯИƎ#%&@$Ɐ∀ʁ01<>/|=+"
    readonly property int steps: 16

    property int step: steps
    property string shown: word
    property real shift: 0                       // game px
    property real skew: 0                        // degrees
    property real dim: 1

    function scrambled(i: int): string {
        const keep = Math.floor(word.length * i / steps);
        let out = word.slice(0, keep);
        for (let k = keep; k < word.length; k++)
            out += glyphs[Math.floor(Math.random() * glyphs.length)];
        return out;
    }
    function apply(i: int): void {
        step = i;
        shown = scrambled(i);
        const moving = i < steps;
        shift = moving ? (Math.random() - 0.5) * 23.04 : 0;
        skew = moving ? (Math.random() - 0.5) * 20 : 0;
        dim = moving && i % 3 === 1 ? 0.35 : 1;
    }
    function start(): void {
        apply(0);
        ticker.restart();
    }
    function stop(): void {
        ticker.stop();
        apply(steps);
    }

    Timer {
        id: ticker
        interval: 50
        repeat: true
        onTriggered: {
            root.apply(root.step + 1);
            if (root.step >= root.steps)
                ticker.stop();
        }
    }

    height: Tokens.px(96 * 1.55, s)

    component Copy: Label {
        anchors.verticalCenter: parent.verticalCenter
        width: face.width
        horizontalAlignment: Text.AlignHCenter
        s: root.s
        size: 96
        spacing: 9.6
        weight: Font.ExtraBold
        text: root.shown
    }

    Item {
        id: face
        width: root.width
        height: root.height
        x: root.shift * root.s
        opacity: root.dim
        transform: Matrix4x4 {
            readonly property real t: Math.tan(root.skew * Math.PI / 180)
            matrix: Qt.matrix4x4(1, t, 0, -t * face.height / 2,
                                 0, 1, 0, 0,
                                 0, 0, 1, 0,
                                 0, 0, 0, 1)
        }

        readonly property real split: (root.dark ? 1.92 : 2.3) * root.s
        Copy {
            x: -face.split
            color: root.dark ? Qt.rgba(200 / 255, 70 / 255, 60 / 255, 0.5) : Qt.rgba(200 / 255, 70 / 255, 60 / 255, 0.7)
        }
        Copy {
            x: face.split
            color: root.dark ? Qt.rgba(70 / 255, 170 / 255, 190 / 255, 0.45) : Qt.rgba(70 / 255, 170 / 255, 190 / 255, 0.6)
        }
        Copy {
            color: root.dark ? Tokens.color.darkGray : "#E6E1CC"
        }
    }
}
