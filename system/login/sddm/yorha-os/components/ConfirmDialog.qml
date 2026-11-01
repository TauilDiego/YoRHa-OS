pragma ComponentBehavior: Bound

import QtQuick
import "../ds"

// The power confirmation (spec 011 FR-013; mockup v3.2 ".dlg", the pause menu's dialog of spec 007):
// ink over the screen and, in its middle, a card with the question, what will happen, the two
// option rows (the action and Cancel; Cancel starts marked) and its key hints.
// Keys, all taken while it is open: ↑↓ move, Enter picks the marked row, Esc cancels. A click on the
// ink cancels; a click on a row picks it. Hovering a row marks it only after the pointer really
// moved (a pointer resting where the dialog opens must never pick the action), as in the shell.
FocusScope {
    id: root

    property real s: 1
    property string action: ""                   // "reboot" | "shutdown"
    property int current: 1                      // 0 the action, 1 Cancel

    readonly property var texts: ({
        reboot: { label: "Reboot", desc: "Restarts the computer." },
        shutdown: { label: "Shut down", desc: "Turns the computer off." }
    })
    readonly property var info: texts[action] ?? { label: "", desc: "" }

    signal confirmed(string action)
    signal cancelled()

    function open(which: string): void {
        action = which;
        current = 1;
        pointerMoved = false;
        pointer.last = Qt.point(NaN, NaN);
        visible = true;
        if (!Tokens.instant)
            fadeIn.restart();
        forceActiveFocus();
    }
    function close(): void {
        fadeIn.stop();
        visible = false;
        opacity = 1;
    }
    function choose(row: int): void {
        if (row === 0)
            confirmed(action);
        else
            cancelled();
    }
    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    visible: false

    NumberAnimation {
        id: fadeIn
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: Tokens.motion.popupFade
        easing.type: Easing.OutQuad
    }

    Keys.onPressed: event => {
        const k = event.key;
        if (k === Qt.Key_Up || k === Qt.Key_Down)
            current = 1 - current;
        else if (k === Qt.Key_Return || k === Qt.Key_Enter)
            choose(current);
        else if (k === Qt.Key_Escape)
            cancelled();
        event.accepted = true;
    }

    // --- the pointer: only a real move lets hover mark a row -----------------------------------------
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
        width: root.u(576)
        height: card.height
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)

        // clicks on the card never reach the ink behind it
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        // the card's hard ink shadow
        Rectangle {
            x: root.u(5.95)
            y: root.u(5.95)
            width: card.width
            height: card.height
            color: Tokens.color.darkGray
        }

        Rectangle {
            id: card
            width: box.width
            height: head.height + body.height
            color: Tokens.color.lightYellow

            Rectangle {
                id: head
                width: parent.width
                height: root.u(49.92)
                color: Tokens.color.darkGray
                Rectangle {
                    x: root.u(19.2)
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.u(13.44)
                    height: width
                    color: Tokens.color.lightYellow
                }
                Label {
                    x: root.u(19.2 + 13.44 + 11.52)
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    size: 22.08
                    spacing: 1.92
                    color: Tokens.color.lightYellow
                    text: root.info.label + "?"
                }
            }

            Column {
                id: body
                y: head.height
                x: root.u(69.12)
                width: card.width - x - root.u(26.88)
                topPadding: root.u(23.04)
                bottomPadding: root.u(21.12)
                spacing: root.u(19.2)

                Label {
                    width: parent.width
                    s: root.s
                    size: 20.16
                    spacing: 0.96
                    weight: Font.Normal
                    wrapMode: Text.Wrap
                    lineHeightMode: Text.FixedHeight
                    lineHeight: Math.round(pixelSize * 1.5)
                    text: root.info.desc
                }

                Column {
                    id: rows
                    width: root.u(307.2)
                    spacing: Tokens.px(Tokens.space.listItemGap, root.s)

                    Repeater {
                        model: 2
                        ListItem {
                            required property int index
                            width: rows.width
                            s: root.s
                            bandSize: 44.16
                            squareSize: 13.44
                            textSize: 19.2
                            text: index === 0 ? root.info.label : "Cancel"
                            selected: root.current === index
                            onHoveredChanged: if (hovered && root.pointerMoved) root.current = index
                            onClicked: {
                                root.current = index;
                                root.choose(index);
                            }
                        }
                    }
                }

                KeyHints {
                    s: root.s
                    textSize: 17.28
                    gapSize: 26.88
                    model: [
                        { key: "↑↓", label: "Select" },
                        { key: "Enter", label: "Confirm" },
                        { key: "Esc", label: "Cancel" }
                    ]
                }
            }
        }
    }
}
