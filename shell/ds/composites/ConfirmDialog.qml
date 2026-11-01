pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"
import "../../strings"

// Confirmation dialog (spec 007, FR-022): over the pop-up's panel, ink (`color.dim`) on the whole
// panel and, in its middle, a Card (confirmW wide, with the mark) holding:
//   the title in the ink band ("Shut down?");
//   the text: what will happen (23 px);
//   the blockers in alert, one line each ("who: why"), and `note` in alert;
//   two action OptionRows, confirmRowsW wide: `actionLabel` and Cancel; the kite starts on `start`;
//   its own footer: ↑↓ Select, Enter Confirm, Esc Cancel.
// Keys, all taken while it is shown (Tab included): ↑↓ move, wrapping; Enter on the action emits
// confirmed(), on Cancel cancelled(); Esc emits cancelled(). A click on the ink emits cancelled(); a
// click on a row confirms that row. Hovering a row moves the kite only after the pointer really
// moved (a pointer resting where the dialog appears must never pick the action).
// The parent fills the panel with it and shows it; reset() puts the kite back on `start`.
FocusScope {
    id: root

    property real s: 1
    property string title
    property string text
    property string note: ""
    property var blockers: []                    // [{ who, why }]
    property string actionLabel
    property string start: "cancel"              // "cancel" | "action"
    property string current: start === "action" ? "action" : "cancel"
    readonly property string row: current

    signal confirmed()
    signal cancelled()

    readonly property var keys: [
        { key: Strings.settings.keyUpDown, label: Strings.settings.select },
        { key: Strings.settings.keyEnter, label: Strings.pause.confirm },
        { key: Strings.settings.keyEsc, label: Strings.pause.cancel }
    ]
    readonly property var rows: [
        { id: "action", option: { type: "action", label: actionLabel, text: "" } },
        { id: "cancel", option: { type: "action", label: Strings.pause.cancel, text: "" } }
    ]
    readonly property var blockerLines: (Array.isArray(blockers) ? blockers : [])
        .map(b => Strings.pause.holding.arg(String(b?.who ?? "")).arg(String(b?.why ?? "")))
    readonly property string alertText: blockerLines.concat(note !== "" ? [note] : []).join("\n")

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    function reset(): void {
        current = start === "action" ? "action" : "cancel";
        pointerMoved = false;
        pointer.last = Qt.point(NaN, NaN);
    }

    function choose(id: string): void {
        if (id === "action")
            confirmed();
        else
            cancelled();
    }

    function rectOf(item: Item): var {
        if (!item)
            return null;
        const p = item.mapToItem(null, 0, 0);
        return { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(item.width), h: Math.round(item.height) };
    }

    // Where the card and the row with the kite are on the screen (logical px), for tests' clicks.
    function geometry(): var {
        return {
            card: rectOf(box),
            item: rectOf(rowRepeater.itemAt(current === "action" ? 0 : 1)),
            action: rectOf(rowRepeater.itemAt(0)),
            cancel: rectOf(rowRepeater.itemAt(1))
        };
    }

    onStartChanged: reset()
    onVisibleChanged: if (visible) reset()

    Keys.onPressed: event => {
        const k = event.key;
        if (k === Qt.Key_Up || k === Qt.Key_Down)
            current = current === "action" ? "cancel" : "action";
        else if (k === Qt.Key_Return || k === Qt.Key_Enter)
            choose(current);
        else if (k === Qt.Key_Escape)
            cancelled();
        event.accepted = true;
    }

    // --- the pointer: only a real move lets hover pick a row ------------------------------------
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
        color: Tokens.color.dim
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.cancelled()
    }

    Item {
        id: box
        width: root.u(Tokens.space.confirmW)
        height: hints.y + hints.height + root.u(24)
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)

        // Clicks on the card never reach the ink behind it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Card {
            id: card
            anchors.fill: parent
            s: root.s
            mark: true
            title: root.title
        }

        Label {
            id: body
            x: card.margin
            y: card.headerH + root.u(26)
            width: parent.width - 2 * card.margin
            s: root.s
            role: "standard"
            font.weight: Font.Medium
            font.variableAxes: ({ "wght": Font.Medium })
            lineHeightMode: Text.FixedHeight
            lineHeight: Math.round(size * 1.5)
            wrapMode: Text.Wrap
            text: root.text
        }

        Label {
            id: alert
            x: card.margin
            y: body.y + body.implicitHeight + root.u(18)
            width: parent.width - 2 * card.margin
            visible: root.alertText !== ""
            s: root.s
            role: "small"
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": Font.DemiBold })
            font.letterSpacing: root.s
            lineHeightMode: Text.FixedHeight
            lineHeight: Math.round(size * 1.4)
            wrapMode: Text.Wrap
            text: root.alertText
            color: Tokens.color.alert
        }

        Column {
            id: rowColumn
            x: Math.round((parent.width - width) / 2)
            y: (alert.visible ? alert.y + alert.implicitHeight : body.y + body.implicitHeight) + root.u(30)
            width: root.u(Tokens.space.confirmRowsW)
            spacing: Tokens.px(Tokens.space.listItemGap, root.s)

            Repeater {
                id: rowRepeater
                model: root.rows

                OptionRow {
                    required property var modelData
                    width: rowColumn.width
                    s: root.s
                    option: modelData.option
                    focused: root.current === modelData.id
                    onHoveredChanged: if (hovered && root.pointerMoved) root.current = modelData.id
                    onActivated: {
                        root.current = modelData.id;
                        root.choose(modelData.id);
                    }
                }
            }
        }

        Rectangle {
            id: rule
            x: card.margin
            y: rowColumn.y + rowColumn.height + root.u(30)
            width: parent.width - 2 * card.margin
            height: Tokens.line(Tokens.space.rule, root.s)
            color: Tokens.color.lightGray
        }

        KeyHints {
            id: hints
            anchors.right: parent.right
            anchors.rightMargin: card.margin
            y: rule.y + rule.height + root.u(16)
            s: root.s
            model: root.keys
        }
    }
}
