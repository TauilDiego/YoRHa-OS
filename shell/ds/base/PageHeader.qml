import QtQuick
import ".."
import "../primitives"

// Page title (FR-006): the title in upper case with a hard text shadow down-right, offset by
// Tokens.shadow.textRatio of the text size, then the subtitle on the same baseline, prefixed
// with "-" like the game ("ITEMS -All Items").
// spec 013 (FR-004, front A): with `animated` (a menu's title), a new title is the game's: the old
// one fades out over motion.titleOut, the row stays empty for titleGap, then the title types at
// titleCps with a letter drawn from the text itself at its tip (TypedText's "letter" tip, used here
// as the clock), and the subtitle after it. typeIn(delay) empties the row and types the title after
// `delay` ms (a menu assembling); it returns when the typing ends (ms from now); hold() empties it
// until then. A change during any of it starts again from what is shown. With Tokens.instant the
// text just changes.
Item {
    id: root

    property real s: 1
    property string title
    property string subtitle
    property bool animated: false

    readonly property int shadowOffset: Math.round(heading.size * Tokens.shadow.textRatio)
    // spec 007: the title's text, so a row can align other text to its baseline.
    readonly property Item titleText: heading

    implicitWidth: sub.visible ? sub.x + sub.implicitWidth : heading.implicitWidth + shadowOffset
    implicitHeight: heading.implicitHeight + shadowOffset

    // --- spec 013: what shows, by phase ---------------------------------------------------------------
    //   ""      the title and subtitle, whole (curTitle and curSub when animated);
    //   "out"   what showed when the change came (outTitle, outSub), fading;
    //   "gap"   nothing, waiting (titleGap, or typeIn's delay);
    //   "title" the title typing, no subtitle;
    //   "sub"   the whole title and the subtitle typing.
    property string phase: ""
    property string curTitle: ""
    property string curSub: ""
    property string outTitle: ""
    property string outSub: ""
    property bool halting: false
    readonly property string subFull: subOf(subtitle)
    // The handlers below read the subtitle through this, not subFull: onSubtitleChanged runs before
    // subFull's binding follows, and would copy the old one (the junction, 01.11: with Tokens.instant
    // SYSTEM showed "-Open Windows" after WINDOWS).
    function subOf(text: string): string {
        return text === "" || text.startsWith("-") ? text : "-" + text;
    }
    // The tip: a letter drawn from the text at every step (the typist's own is only drawn once its
    // animation runs, so the first step would show nothing).
    property string tip: ""
    readonly property string typedPart: Array.from(typist.text).slice(0, typist.count).join("") + tip
    Connections {
        target: typist
        function onCountChanged(): void {
            const letters = Array.from(typist.text).filter(c => c.trim() !== "");
            root.tip = (root.phase === "title" || root.phase === "sub") && letters.length > 0
                && typist.count < Array.from(typist.text).length
                ? letters[Math.floor(Math.random() * letters.length)] : "";
        }
    }
    readonly property string headText: !animated && phase === "" ? title
        : phase === "" || phase === "sub" ? curTitle : phase === "out" ? outTitle : phase === "title" ? typedPart : ""
    readonly property string subText: !animated && phase === "" ? subFull
        : phase === "" ? curSub : phase === "out" ? outSub : phase === "sub" ? typedPart : ""
    readonly property bool busy: phase !== ""

    // A frame may already be holding it (PopupFrame.open() runs before this).
    Component.onCompleted: {
        if (phase === "") {
            curTitle = title;
            curSub = subOf(subtitle);
        }
    }

    function settle(): void {
        stopAll();
        curTitle = title;
        curSub = subOf(subtitle);
        phase = "";
    }

    // Empty until typeIn().
    function hold(): void {
        if (Tokens.instant)
            return;
        stopAll();
        phase = "gap";
    }

    function typeIn(delay: int): int {
        if (Tokens.instant) {
            settle();
            return 0;
        }
        stopAll();
        phase = "gap";
        delayPause.duration = Math.max(0, delay);
        delayAnim.start();
        return delay + typeMs(title) + typeMs(subOf(subtitle));
    }

    // The planned typing of `text`, in ms.
    function typeMs(text: string): int {
        return Math.round(Array.from(text).length * 1000 / Tokens.motion.titleCps);
    }

    function changed(): void {
        if (!animated || Tokens.instant) {
            settle();
            return;
        }
        if (phase === "gap" && !outAnim.running)
            return;                              // waiting for typeIn's delay (or held): it types the new one
        const shownTitle = headText, shownSub = subText;
        stopAll();
        outTitle = shownTitle;
        outSub = shownSub;
        phase = "out";
        outAnim.start();
    }
    onTitleChanged: changed()
    onSubtitleChanged: changed()

    function stopAll(): void {
        outAnim.stop();
        delayAnim.stop();
        halting = true;
        typist.complete();
        halting = false;
        opacity = 1;
    }

    function typeTitle(): void {
        curTitle = title;
        curSub = subOf(subtitle);
        phase = "title";
        typist.text = curTitle;
        typist.shown = 0;                        // no stale count before the animation's first step
        typist.restartKey = typist.restartKey + 1;
    }

    // Out, empty, then typed: one animation, so the gap ends on a frame (no timer's lag).
    SequentialAnimation {
        id: outAnim
        NumberAnimation { target: root; property: "opacity"; from: 1; to: 0; duration: Tokens.motion.titleOut }
        ScriptAction {
            script: {
                root.phase = "gap";
                root.opacity = 1;
            }
        }
        PauseAnimation { duration: Tokens.motion.titleGap }
        ScriptAction { script: root.typeTitle() }
    }
    SequentialAnimation {
        id: delayAnim
        PauseAnimation { id: delayPause }
        ScriptAction { script: root.typeTitle() }
    }

    // The clock of the typing: never drawn.
    TypedText {
        id: typist
        visible: false
        s: root.s
        role: "pageHeader"
        maxLines: 1
        cps: Tokens.motion.titleCps
        tip: "letter"
        instant: Tokens.instant
        onDone: {
            if (root.halting)
                return;
            if (root.phase === "title" && root.curSub !== "") {
                root.phase = "sub";
                text = root.curSub;
                shown = 0;
                restartKey = restartKey + 1;
            } else if (root.phase === "title" || root.phase === "sub")
                root.phase = "";
        }
    }

    Label {
        x: root.shadowOffset
        y: root.shadowOffset
        s: root.s
        role: "pageHeader"
        upper: true
        text: root.headText
        color: Tokens.color.textShadow
    }

    Label {
        id: heading
        s: root.s
        role: "pageHeader"
        upper: true
        text: root.headText
    }

    Label {
        id: sub
        x: heading.implicitWidth + root.shadowOffset + Tokens.px(10, root.s)
        anchors.baseline: heading.baseline
        visible: root.subtitle !== ""
        s: root.s
        role: "subheader"
        text: root.subText
    }
}
