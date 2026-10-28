pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../ds/composites"
import "../services"

// Transmissions on one monitor (spec 008, R9): a transparent window over the whole monitor on the
// Overlay layer (a critical one shows even over a full-screen window), with the critical band right
// under the bar and the stack (TransmissionStack) in the Position option's place, under the band
// while it shows. Input only on the transmissions (the mask is the union of their boxes); the
// keyboard only while a reply field is open on this monitor (Exclusive, then back to None, which
// gives the keyboard back to the window that had it: spike T004, item 5). shell.qml creates it only
// while the monitor has something to show.
PanelWindow {
    id: root

    property var modelData                       // the ShellScreen
    screen: modelData

    signal openLogRequested()

    readonly property string monitorName: modelData?.name ?? ""
    readonly property real dpr: Tokens.scaleOf(monitorName)
    readonly property real s: Settings.uiScale * Math.min(1, width / 1920, height / 1080)
    readonly property int barH: Settings.barHeight
    readonly property string position: NotifyPrefs.position
    readonly property var N: Tokens.notify

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rien-notify"
    WlrLayershell.keyboardFocus: replyOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    // --- what this monitor shows -------------------------------------------------------------------
    readonly property var items: {
        const now = Date.now();
        return NotifyStore.stack.filter(t => t.monitor === root.monitorName).map(t => {
            const remaining = NotifyStore.remainingOf(t.id);
            return {
                key: t.key, id: t.id, entry: t.entry, speaker: NotifyStore.speakerOf(t.entry), count: t.count,
                typeFrom: t.from, typeMs: t.typed ? 0 : Math.max(0, Math.round(t.typedAt - now)), typeKey: t.typedAt,
                lifeFrac: t.typed && t.total ? remaining / t.total : 1,
                lifeMs: t.typed && t.total && !t.paused ? remaining : 0,
                paused: t.paused, replying: t.replying
            };
        });
    }
    readonly property bool replyOpen: items.some(i => i.replying)
    readonly property var crit: NotifyStore.critical && NotifyStore.critical.monitor === monitorName ? NotifyStore.critical : null
    readonly property var critEntries: crit ? crit.ids.map(id => NotifyStore.entry(id)).filter(e => e !== null) : []

    // --- the critical band, under the bar (the top band's position: right on its edge) ---------------
    CriticalBand {
        id: band
        visible: root.critEntries.length > 0
        y: root.position === "top" ? root.barH : root.barH + Tokens.px(root.N.stackTop, root.s)
        width: root.width
        height: implicitHeight
        s: root.s
        dpr: root.dpr
        instant: NotifyStore.instantTyping || NotifyStore.fixed
        entries: root.critEntries
        page: root.crit?.page ?? 0
        speaker: NotifyStore.speakerOf(root.critEntries[root.crit?.page ?? 0] ?? null)
        onPageStepped: dir => NotifyStore.pageStep(dir)
        onCloseClicked: id => NotifyStore.hide(id)
        onActionClicked: (id, action) => NotifyStore.invoke(id, action)
    }

    TransmissionStack {
        id: stack
        anchors.fill: parent
        s: root.s
        dpr: root.dpr
        position: root.position
        items: root.items
        overflow: NotifyStore.overflow
        instant: Tokens.instant || NotifyStore.fixed
        topInset: band.visible && root.position !== "subtitle" ? band.y + band.height + Tokens.px(root.N.stackGap, root.s)
                : root.position === "top" ? root.barH : root.barH + Tokens.px(root.N.stackTop, root.s)
        bottomInset: Tokens.px(root.N.subtitleBottom, root.s)

        onClicked: (id, button) => {
            const e = NotifyStore.entry(id);
            if (button === Qt.LeftButton && e?.hasDefault && e.alive)
                NotifyStore.invoke(id, "default");
            else
                NotifyStore.hide(id);
        }
        onCloseClicked: id => NotifyStore.hide(id)
        onActionClicked: (id, action) => NotifyStore.invoke(id, action)
        onHoverChanged: (id, on) => NotifyStore.pause(id, on)
        onReplyOpened: id => {
            NotifyStore.setReplying(id, true);
            Qt.callLater(() => stack.viewOf(id)?.focusReply());
        }
        onReplySent: (id, text) => NotifyStore.reply(id, text)
        onReplyCancelled: id => NotifyStore.setReplying(id, false)
        onTypedOut: id => NotifyStore.typed(id)
        onOverflowClicked: root.openLogRequested()
    }

    // --- input only on what is drawn ------------------------------------------------------------------
    property var maskBoxes: []
    function refreshMask(): void {
        const out = stack.boxes().map(b => ({ x: b.x, y: b.y, w: b.w, h: b.h }));
        if (band.visible)
            out.push({ x: 0, y: Math.round(band.y), w: Math.round(band.width), h: Math.round(band.height) });
        maskBoxes = out;
    }
    onItemsChanged: maskTimer.restart()
    onCritEntriesChanged: maskTimer.restart()
    Connections {
        target: NotifyStore
        function onRevisionChanged(): void {
            maskTimer.restart();
        }
    }
    Timer {
        id: maskTimer
        interval: 40
        onTriggered: {
            root.refreshMask();
            maskSettle.restart();
        }
    }
    Timer {
        id: maskSettle                            // once more after the slides and fades
        interval: 220
        onTriggered: root.refreshMask()
    }
    Variants {
        id: maskParts
        model: root.maskBoxes
        Region {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h
        }
    }
    mask: Region {
        regions: maskParts.instances
    }
    Component.onCompleted: maskTimer.restart()

    // For `notify dump`: { stack: [{ id, x, y, w, h }], critical: box or null } in logical px.
    function dumpBoxes(): var {
        return {
            stack: stack.boxes(),
            critical: band.visible ? { x: 0, y: Math.round(band.y), w: Math.round(band.width), h: Math.round(band.height) } : null
        };
    }
    readonly property real critBottom: band.visible ? band.y + band.height : 0
}
