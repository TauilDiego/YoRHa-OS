pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../TextCut.js" as TextCut

// Typed text (spec 008, FR-006, R8): a styled text (<b>, <i>, <u>, <br> only: NotifyText.sanitize)
// that appears character by character, with a block cursor at its end while it types. One
// NumberAnimation per text: `shown` goes from `from` to the end in `ms` milliseconds (the caller
// plans it: Tokens.notify.cps, at most typeMaxMs). The box has the whole text's height from the
// start (the rest is laid out, invisible), so nothing below it moves while it types.
//   instant: the whole text at once, no cursor (fixtures, reduced motion, Typing: Off; FR-031);
//   restartKey: a new value types again (a replacement, a log entry receiving the focus);
//   maxLines: the text is cut there with an ellipsis (`truncated` says so).
// complete() shows it all now; done() when the end is reached.
Item {
    id: root

    property real s: 1
    property string text
    property int from: 0
    property int ms: 0
    property var restartKey: 0
    property bool instant: false
    property int maxLines: Tokens.notify.lines
    property string role: "bandBody"
    property color color: Tokens.notify.bandBody
    property real stillAt: -1                    // ≥ 0: a still frame at that fraction, cursor shown (gallery)

    signal done()

    readonly property int length: TextCut.visibleLength(text)
    property real shown: length
    readonly property bool typing: anim.running || stillAt >= 0
    readonly property bool truncated: full.truncated
    readonly property var textStyle: Tokens.type[role] ?? Tokens.type.bandBody

    implicitWidth: full.implicitWidth
    implicitHeight: full.implicitHeight

    function complete(): void {
        anim.stop();
        if (shown < length) {
            shown = length;
            done();
        }
    }

    function start(): void {
        anim.stop();
        if (stillAt >= 0) {
            shown = Math.floor(length * stillAt);
            return;
        }
        if (instant || ms <= 0 || from >= length) {
            shown = length;
            done();
            return;
        }
        anim.from = Math.max(0, Math.min(from, length));
        anim.to = length;
        anim.duration = ms;
        anim.start();
    }
    onRestartKeyChanged: start()
    onInstantChanged: if (instant) complete()
    Component.onCompleted: start()

    NumberAnimation {
        id: anim
        target: root
        property: "shown"
        easing.type: Easing.Linear
        onFinished: root.done()
    }

    component Body: Label {
        width: root.width
        s: root.s
        role: root.role
        textFormat: Text.StyledText
        wrapMode: Text.Wrap
        maximumLineCount: root.maxLines
        elide: Text.ElideRight
        lineHeightMode: Text.FixedHeight
        lineHeight: Math.round(root.textStyle.lineHeight * root.s)
        color: root.color
    }

    // The whole text: the box's size, and what is drawn once the typing is done.
    Body {
        id: full
        text: root.text
        visible: !root.typing
    }

    // While typing: the first characters, and the cursor after them.
    Body {
        id: part
        visible: root.typing
        text: TextCut.cut(root.text, Math.floor(root.shown))
    }
    Rectangle {
        id: cursor
        visible: root.typing
        readonly property rect at: part.positionToRectangle(Math.floor(root.shown))
        x: Math.round(at.x + Tokens.px(1, root.s))
        y: Math.round(at.y + (at.height - height) / 2)
        width: Math.round(part.font.pixelSize * 0.5)
        height: Math.round(part.font.pixelSize * 1.05)
        color: root.color
    }
}
