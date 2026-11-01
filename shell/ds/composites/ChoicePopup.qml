pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import ".."
import "../primitives"
import "../base"

// Choice pop-up (spec 013, US6, FR-025 to FR-027): the game's little window of values, glued to the
// right of the option row that opened it. The parent fills the menu's panel with it and sets `open`.
//   values: the labels; current: the row with the cursor; multi: marks boxes instead of picking one,
//   `marked` being the marked indices (ascending, never empty: the last mark can't be taken off).
//   anchorX / anchorY / anchorH: the option row's right edge, top and height; limitTop / limitBottom:
//   the room the pop-up may take; all in this item's coordinates (px). It starts at the row's top and
//   goes up when the bottom edge is near; with more values than fit, the list scrolls in whole rows.
// Look: the menu dims to Tokens.motion.dialogTo over dialogDim; the plate fades in with a short blur
// (the prototype's E9: 33 ms delay, 120 ms, 3 px). The list is ListItems whose texts are
// ScrollingLabels (the current one scrolls when it doesn't fit), and the kite is on the right,
// mirrored, pointing left.
// Keys, all taken while open: ↑↓ move (wrapping), Enter picks (or marks / unmarks), Esc and a click
// outside emit dismissed(). A single choice emits picked(index) and the parent closes it; a multi one
// keeps its marks in `marked` and the parent stores them when it closes (FR-026). The pointer moves the
// cursor only after it really moved, so a pointer resting where the pop-up opens picks nothing.
FocusScope {
    id: root

    property real s: 1
    property bool open: false
    property var values: []
    property int current: 0
    property bool multi: false
    property var marked: []
    property real anchorX: 0
    property real anchorY: 0
    property real anchorH: 0
    property real limitTop: 0
    property real limitBottom: 0

    signal picked(int index)
    signal toggled(int index)
    signal dismissed()

    readonly property int count: values?.length ?? 0
    readonly property int listW: u(420)                     // game px; longer texts scroll
    readonly property int selectorRoom: u(Tokens.space.selectorGap) + u(Tokens.space.selectorW)
    readonly property int rowH: u(Tokens.space.listItemH)
    readonly property int pitch: rowH + u(Tokens.space.listItemGap)
    readonly property int railRoom: u(Tokens.space.railGap) + Tokens.line(Tokens.space.rail, s)
    readonly property int padY: railRoom + u(8)
    readonly property int padX: u(16)
    readonly property int plateW: padX + listW + selectorRoom + padX
    readonly property int visibleRows: Math.max(1, Math.min(count, Math.floor((limitBottom - limitTop - 2 * padY + pitch - rowH) / pitch)))
    readonly property int plateH: 2 * padY + visibleRows * pitch - (pitch - rowH)
    readonly property int plateX: Math.max(padX, Math.min(Math.round(anchorX + u(12)), width - plateW - padX))
    readonly property int plateY: Math.max(limitTop, Math.min(Math.round(anchorY - padY), limitBottom - plateH))

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    // --- the cursor and the marks ----------------------------------------------------------------------
    function move(dir: int): void {
        if (count > 0)
            current = ((current + dir) % count + count) % count;
    }

    // Marks or unmarks value `i`; false when it is the last mark (one must stay).
    function toggle(i: int): bool {
        if (!multi || i < 0 || i >= count)
            return false;
        const at = marked.indexOf(i);
        if (at >= 0 && marked.length === 1)
            return false;
        const next = marked.slice();
        if (at >= 0)
            next.splice(at, 1);
        else
            next.push(i);
        marked = next.sort((a, b) => a - b);
        toggled(i);
        return true;
    }

    // Enter on value `i`: picks it, or marks / unmarks it.
    function activate(i: int): void {
        if (i < 0 || i >= count)
            return;
        current = i;
        if (multi)
            toggle(i);
        else
            picked(i);
    }

    // Whole rows, just enough to show the cursor's.
    property real scrollY: 0
    function follow(): void {
        if (pitch <= 0)
            return;
        let first = Math.round(scrollY / pitch) || 0;
        if (current < first)
            first = current;
        else if (current >= first + visibleRows)
            first = current - visibleRows + 1;
        first = Math.max(0, Math.min(first, count - visibleRows));
        scrollY = first * pitch;
    }
    onCurrentChanged: follow()
    onVisibleRowsChanged: follow()
    onOpenChanged: {
        if (open) {
            pointerMoved = false;
            pointer.last = Qt.point(NaN, NaN);
            scrollY = 0;
            follow();
        }
    }

    function rectOf(item: Item): var {
        if (!item)
            return null;
        const p = item.mapToItem(null, 0, 0);
        return { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(item.width), h: Math.round(item.height) };
    }

    // Where the plate and the row with the cursor are on the screen (logical px), for tests' clicks.
    function geometry(): var {
        return { plate: rectOf(plate), item: rectOf(rows.itemAt(current)), rows: visibleRows };
    }

    // --- the dim and the plate's fade -----------------------------------------------------------------
    property real dimT: open ? 1 : 0
    Behavior on dimT {
        NumberAnimation {
            duration: Tokens.motion.dialogDim
            easing.type: Easing.InOutQuad
        }
    }
    property real plateT: open ? 1 : 0
    Behavior on plateT {
        SequentialAnimation {
            PauseAnimation { duration: root.open && !Tokens.instant ? 33 : 0 }
            NumberAnimation {
                duration: Tokens.instant ? 0 : root.open ? 120 : 80
                easing.type: Easing.OutCubic
            }
        }
    }

    visible: open || dimT > 0 || plateT > 0
    enabled: open

    Keys.onPressed: event => {
        const k = event.key;
        if (k === Qt.Key_Up)
            move(-1);
        else if (k === Qt.Key_Down)
            move(1);
        else if (k === Qt.Key_Return || k === Qt.Key_Enter)
            activate(current);
        else if (k === Qt.Key_Escape)
            dismissed();
        event.accepted = true;
    }

    // The pointer: only a real move lets hover take the cursor.
    property bool pointerMoved: false
    HoverHandler {
        id: pointer
        property point last: Qt.point(NaN, NaN)
        onPointChanged: {
            const p = point.scenePosition;
            if (p.x === last.x && p.y === last.y)
                return;
            const first = isNaN(last.x);
            last = p;
            if (!first)
                root.pointerMoved = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: (1 - Tokens.motion.dialogTo) * root.dimT
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismissed()
    }

    // A row's face: the mark and the text, in one color. The dark face is over the paper, the light one
    // over the ink band, as the ListItem's two faces; the light text follows the dark one.
    component Face: Item {
        id: face
        property color ink
        property string text
        property bool checked: false
        property bool running: false
        property var leader: null
        readonly property Item label: txt
        readonly property int square: root.u(Tokens.space.square)
        readonly property int textX: root.padX + square + root.padX
        height: root.rowH

        Rectangle {
            x: root.padX
            anchors.verticalCenter: parent.verticalCenter
            width: face.square
            height: width
            visible: root.multi
            color: face.checked ? face.ink : "transparent"
            border.width: root.u(2)
            border.color: face.ink
        }
        Square {
            x: root.padX
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.multi
            s: root.s
            color: face.ink
        }
        ScrollingLabel {
            id: txt
            x: face.textX
            width: Math.max(0, face.width - face.textX - root.padX)
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            role: "listButton"
            text: face.text
            color: face.ink
            running: face.running
            follow: face.leader
        }
    }

    Item {
        id: plate
        x: root.plateX
        y: root.plateY
        width: root.plateW
        height: root.plateH
        opacity: root.plateT

        // The blur only while the fade runs: a layer is a cost.
        layer.enabled: root.plateT > 0 && root.plateT < 1
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 16
            blur: 0.2 * (1 - root.plateT)
        }

        // Clicks on the plate never reach the dim behind it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Rectangle {
            x: Tokens.px(Tokens.shadow.boxX, root.s)
            y: Tokens.px(Tokens.shadow.boxY, root.s)
            width: parent.width
            height: parent.height
            color: Tokens.color.boxShadow
        }
        Rectangle {
            anchors.fill: parent
            color: Tokens.color.lightYellow
        }

        Item {
            x: root.padX
            y: root.padY - root.railRoom
            width: root.listW + root.selectorRoom
            height: root.plateH - 2 * root.padY + 2 * root.railRoom
            clip: true

            Column {
                id: column
                y: root.railRoom - root.scrollY
                width: root.listW
                spacing: root.u(Tokens.space.listItemGap)

                Repeater {
                    id: rows
                    model: root.values

                    Item {
                        id: row
                        required property int index
                        required property var modelData
                        readonly property bool isCurrent: index === root.current
                        readonly property bool isMarked: root.marked.includes(index)

                        width: column.width
                        height: root.rowH

                        ListItem {
                            id: item
                            width: parent.width
                            s: root.s
                            variant: "plain"
                            text: ""
                            showMark: false
                            showSelector: false
                            state: row.isCurrent ? "hovered" : "normal"
                            onHoveredChanged: if (hovered && root.pointerMoved) root.current = row.index
                            onClicked: root.activate(row.index)
                        }

                        // The dark face over the paper (right of the ink), the light one over the ink.
                        Item {
                            x: item.inkW
                            width: row.width - item.inkW
                            height: root.rowH
                            clip: true
                            visible: width > 0
                            Face {
                                id: dark
                                x: -item.inkW
                                width: row.width
                                ink: Tokens.color.darkGray
                                text: String(row.modelData)
                                checked: row.isMarked
                                running: row.isCurrent && root.open
                            }
                        }
                        Item {
                            width: item.inkW
                            height: root.rowH
                            clip: true
                            visible: width > 0
                            Face {
                                width: row.width
                                ink: Tokens.color.lightYellow
                                text: String(row.modelData)
                                checked: row.isMarked
                                leader: dark.label
                            }
                        }

                        // The kite, mirrored: on the right, pointing left at the row.
                        Item {
                            x: row.width + root.u(Tokens.space.selectorGap)
                            y: Math.round((root.rowH - selector.height) / 2)
                            width: selector.width
                            height: selector.height
                            transform: Scale {
                                origin.x: selector.width / 2
                                xScale: -1
                            }
                            Selector {
                                id: selector
                                s: root.s
                                shown: row.isCurrent && root.open
                                tone: "dark"
                            }
                        }
                    }
                }
            }
        }
    }
}
