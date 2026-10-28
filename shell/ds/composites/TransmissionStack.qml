pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"
import "../../strings"

// The stack of transmissions on one monitor (spec 008, FR-004, FR-005, FR-018, FR-041), in one of
// the three positions of the Position option:
//   corner    under the bar (topInset), against the right edge, Tokens.notify.stackW wide, the newest
//             on top; the "+N in log" line under it, on the right;
//   top       bands as wide as the monitor right under the bar, the text in a centered column,
//             2 px apart, the newest on top;
//   subtitle  centered at the bottom, Tokens.notify.subtitleW wide, its bottom bottomInset above the
//             monitor's bottom (above the OSD's area), the newest at the bottom.
// A new transmission sweeps in from its edge (Tokens.notify.sweep); one that leaves fades out
// (Tokens.notify.fade) and the others slide into place. A change of position moves them at once.
// `instant` (fixtures, reduced motion): nothing animates. Delegates are kept by key (a ListModel
// synced with `items`), so a change of one item never rebuilds the others.
//   items: [{ key, id, entry, speaker, count, typeFrom, typeMs, typeKey, lifeFrac, lifeMs, paused,
//            replying }], newest first.
// The parent sets the size (the whole monitor).
Item {
    id: root

    property real s: 1
    property real dpr: 1
    property var items: []
    property string position: "corner"
    property real topInset: 0
    property real bottomInset: Tokens.px(Tokens.notify.subtitleBottom, s)
    property int overflow: 0
    property bool instant: false
    property bool ready: true                    // the window is mapped: rows can appear

    signal appeared(int id)                      // a row is on screen for the first time
    signal clicked(int id, int button)
    signal closeClicked(int id)
    signal actionClicked(int id, string action)
    signal hoverChanged(int id, bool hovering)
    signal replyOpened(int id)
    signal replySent(int id, string text)
    signal replyCancelled(int id)
    signal typedOut(int id)
    signal overflowClicked()

    readonly property var nt: Tokens.notify
    function u(v: real): int {
        return Tokens.px(v, s);
    }

    readonly property int bandW: position === "top" ? width
                                : position === "subtitle" ? Math.min(u(nt.subtitleW), width - 2 * u(nt.stackRight))
                                : Math.min(u(nt.stackW), width - 2 * u(nt.stackRight))
    readonly property int bandX: position === "top" ? 0
                                : position === "subtitle" ? Math.round((width - bandW) / 2)
                                : width - u(nt.stackRight) - bandW
    readonly property int gap: position === "top" ? u(nt.topGap) : u(nt.stackGap)

    // --- the delegates, kept by key ------------------------------------------------------------------
    ListModel {
        id: slots
    }
    function indexOfKey(k: string): int {
        for (let i = 0; i < slots.count; i++)
            if (slots.get(i).key === k)
                return i;
        return -1;
    }
    function sync(): void {
        const keys = items.map(i => i.key);
        // Gone: fade out (or go at once).
        for (let i = slots.count - 1; i >= 0; i--) {
            const sl = slots.get(i);
            if (!keys.includes(sl.key) && !sl.leaving) {
                if (instant)
                    slots.remove(i);
                else
                    slots.setProperty(i, "leaving", true);
            }
        }
        // New: in the items' order (the newest first), the leaving ones keep their place.
        keys.forEach((k, n) => {
            const at = indexOfKey(k);
            if (at < 0) {
                slots.insert(Math.min(n, slots.count), { key: k, leaving: false });
            }
        });
        // Present ones follow the items' order.
        let pos = 0;
        for (const k of keys) {
            while (pos < slots.count && slots.get(pos).leaving)
                pos++;
            const at = indexOfKey(k);
            if (at > pos)
                slots.move(at, pos, 1);
            pos++;
        }
        Qt.callLater(root.layout);
    }
    onItemsChanged: sync()
    Component.onCompleted: sync()

    property bool jump: false                    // the next layout moves without sliding
    onPositionChanged: {
        jump = true;
        layout();
    }
    onTopInsetChanged: layout()
    onBottomInsetChanged: layout()
    onWidthChanged: layout()
    onHeightChanged: layout()

    function layout(): void {
        const slide = !instant && !jump;
        jump = false;
        const list = [];
        for (let i = 0; i < rows.count; i++) {
            const d = rows.itemAt(i);
            if (d)
                list.push(d);
        }
        if (position === "subtitle") {
            let bottom = height - bottomInset;
            for (const d of list) {
                d.slide = slide && d.placed;
                d.y = bottom - d.height;
                d.placed = true;
                bottom -= d.height + gap;
            }
            more.y = bottom - more.height;
        } else {
            let y = topInset;
            for (const d of list) {
                d.slide = slide && d.placed;
                d.y = y;
                d.placed = true;
                y += d.height + gap;
            }
            more.y = y + (position === "top" ? u(nt.stackGap) - gap : 0);
        }
    }

    Repeater {
        id: rows
        model: slots

        Item {
            id: row
            required property string key
            required property bool leaving
            required property int index

            property var item: null
            readonly property var found: root.items.find(i => i.key === key) ?? null
            onFoundChanged: if (found) item = found
            Component.onCompleted: {
                item = found;
                show();
            }
            // Once, as soon as the window is mapped: the sweep in, and the store is told.
            property bool seen: false
            function show(): void {
                if (seen || !root.ready || !item)
                    return;
                seen = true;
                if (!root.instant)
                    enter.start();
                else
                    reveal.width = Qt.binding(() => row.width);
                root.appeared(item.id);
            }
            Connections {
                target: root
                function onReadyChanged(): void {
                    row.show();
                }
            }

            property bool placed: false
            property bool slide: false
            readonly property var view: tx
            x: root.bandX
            width: root.bandW
            height: tx.implicitHeight
            onHeightChanged: Qt.callLater(root.layout)
            Behavior on y {
                enabled: row.slide
                NumberAnimation { duration: root.nt.sweep; easing.type: Easing.OutCubic }
            }

            // The sweep in: a clip that opens from the stack's edge (the right one in the corner).
            Item {
                id: reveal
                x: root.position === "corner" ? row.width - width : 0
                width: 0
                height: row.height
                clip: enter.running

                Transmission {
                    id: tx
                    x: -reveal.x
                    width: row.width
                    s: root.s
                    dpr: root.dpr
                    layout: root.position
                    instant: root.instant
                    entry: row.item?.entry ?? ({})
                    speaker: row.item?.speaker ?? ""
                    count: row.item?.count ?? 1
                    typeFrom: row.item?.typeFrom ?? 0
                    typeMs: row.item?.typeMs ?? 0
                    typeKey: row.item?.typeKey ?? 0
                    lifeFrac: row.item?.lifeFrac ?? 1
                    lifeMs: row.item?.lifeMs ?? 0
                    paused: row.item?.paused ?? false
                    replying: row.item?.replying ?? false
                    enabled: !row.leaving
                    onClicked: button => root.clicked(row.item.id, button)
                    onCloseClicked: root.closeClicked(row.item.id)
                    onActionClicked: id => root.actionClicked(row.item.id, id)
                    onHoverChanged: on => root.hoverChanged(row.item.id, on)
                    onReplyOpened: root.replyOpened(row.item.id)
                    onReplySent: text => root.replySent(row.item.id, text)
                    onReplyCancelled: root.replyCancelled(row.item.id)
                    onTypedOut: if (row.item && row.seen) root.typedOut(row.item.id)
                }
            }
            NumberAnimation {
                id: enter
                target: reveal
                property: "width"
                from: 0
                to: row.width
                duration: root.nt.sweep
                easing.type: Easing.OutCubic
                onFinished: reveal.width = Qt.binding(() => row.width)
            }

            onLeavingChanged: if (leaving) fade.start()
            NumberAnimation {
                id: fade
                target: row
                property: "opacity"
                to: 0
                duration: root.nt.fade
                onFinished: {
                    const i = root.indexOfKey(row.key);
                    if (i >= 0)
                        slots.remove(i);
                    Qt.callLater(root.layout);
                }
            }

            function box(): var {
                return { x: Math.round(x), y: Math.round(y), w: Math.round(width), h: Math.round(height) };
            }
        }
    }

    // "+N in log": the unread ones that left before they were typed out (FR-018).
    Item {
        id: more
        visible: root.overflow > 0 && rows.count > 0
        x: root.position === "top" ? root.width - root.u(root.nt.topPad) - width : root.bandX + root.bandW - width
        width: moreLabel.implicitWidth + 2 * root.u(14)
        height: moreLabel.implicitHeight + 2 * root.u(8)

        Band {
            anchors.fill: parent
            s: root.s
            dpr: root.dpr
            shadow: root.position !== "top"
        }
        Label {
            id: moreLabel
            anchors.centerIn: parent
            s: root.s
            role: "bandWho"
            font.pixelSize: Tokens.px(16, root.s)
            text: Strings.notify.overflow.arg(root.overflow)
            color: Tokens.notify.bandText
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.overflowClicked()
        }
    }

    // The boxes on screen, for the window's input mask and the dump: { id → box }, and "more".
    function boxes(): var {
        const out = [];
        for (let i = 0; i < rows.count; i++) {
            const d = rows.itemAt(i);
            if (d && !d.leaving && d.item)
                out.push(Object.assign({ id: d.item.id }, d.box()));
        }
        if (more.visible)
            out.push({ id: "more", x: Math.round(more.x), y: Math.round(more.y), w: Math.round(more.width), h: Math.round(more.height) });
        return out;
    }
    // The transmission view of entry `id` (e.g. to focus its reply field).
    function viewOf(id: int): var {
        for (let i = 0; i < rows.count; i++) {
            const d = rows.itemAt(i);
            if (d?.item?.id === id)
                return d.view;
        }
        return null;
    }
}
