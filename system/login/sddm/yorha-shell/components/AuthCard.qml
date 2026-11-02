pragma ComponentBehavior: Bound

import QtQuick
import "../ds"

// The "Authentication" card (spec 011 FR-006, FR-008, FR-010, FR-011, FR-012; mockup v3.2 ".card"):
// the ink bar, then, in the body, the user name field (only for "Other user…"), the password field
// and the message line.
// Password: one square per character. They pop in and shrink out; past the field's width the oldest
// slide off to the left under an ellipsis, and the caret stays visible. A clear makes them all
// fold away. The real text lives in a hidden TextInput, so the system's keyboard layout and input
// method apply (spec edge case "Teclado").
// `locked` (checking) makes both fields read-only; `busy` shows the loading ring in the message line.
// Keys reach the parent first through keyPressed(event, field), before the field's own handling.
Item {
    id: root

    property real s: 1
    property bool otherUser: false
    property bool locked: false
    property bool busy: false
    property string message: ""
    property bool error: false

    readonly property string password: pw.text
    readonly property string userName: nameInput.text
    readonly property bool nameFocused: nameInput.activeFocus
    readonly property bool passwordFocused: pw.activeFocus

    signal keyPressed(var event, string field)

    function focusPassword(): void {
        pw.forceActiveFocus();
    }
    function focusName(): void {
        nameInput.forceActiveFocus();
    }
    function clearPassword(animated: bool): void {
        pw.text = "";
        squares.clearAll(animated);
    }
    function clearName(): void {
        nameInput.text = "";
    }

    // --- sizes (mockup v3.2, game px) ------------------------------------------------------------
    function u(v: real): int {
        return Tokens.px(v, root.s);
    }
    readonly property int fieldH: u(49.92)
    readonly property int fieldPad: u(17.28)
    readonly property color fieldRest: "#C7C1A5"

    implicitWidth: u(499.2)
    implicitHeight: card.height

    // the card's hard shadow
    Rectangle {
        x: root.u(4.8)
        y: root.u(4.8)
        width: card.width
        height: card.height
        color: Tokens.color.boxShadow
    }

    Rectangle {
        id: card
        width: root.width
        height: bar.height + body.height
        color: Tokens.color.lightYellow

        Rectangle {
            id: bar
            width: parent.width
            height: root.u(48.5)
            color: Tokens.color.darkGray
            Rectangle {
                x: root.u(17.28)
                anchors.verticalCenter: parent.verticalCenter
                width: root.u(13.44)
                height: width
                color: Tokens.color.lightYellow
            }
            Label {
                x: root.u(17.28 + 13.44 + 11.52)
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                size: 20.16
                spacing: 1.92
                color: Tokens.color.lightYellow
                text: "Authentication"
            }
        }

        Column {
            id: body
            y: bar.height
            x: root.fieldPad
            width: parent.width - 2 * root.fieldPad
            topPadding: root.fieldPad
            bottomPadding: root.fieldPad
            spacing: root.u(13.44)

            // --- "Other user…": the name ---------------------------------------------------------
            Rectangle {
                id: nameField
                visible: root.otherUser
                width: parent.width
                height: root.fieldH
                color: nameInput.activeFocus ? Tokens.color.darkGray : root.fieldRest
                onVisibleChanged: if (visible && !Tokens.instant) fieldIn.restart()

                NumberAnimation {
                    id: fieldIn
                    target: nameField
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutQuad
                }

                Label {
                    x: root.fieldPad
                    anchors.verticalCenter: parent.verticalCenter
                    visible: nameInput.text === ""
                    s: root.s
                    size: 19.2
                    spacing: 1.536
                    weight: Font.Normal
                    color: nameInput.activeFocus ? Tokens.color.lightGray : Tokens.color.mediumGray
                    text: "User name"
                }
                TextInput {
                    id: nameInput
                    x: root.fieldPad
                    width: parent.width - 2 * root.fieldPad
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    readOnly: root.locked
                    color: activeFocus ? Tokens.color.lightYellow : Tokens.color.darkGray
                    selectionColor: Tokens.color.mediumGray
                    font.family: Tokens.bodyFamily
                    font.pixelSize: root.u(19.2)
                    font.weight: Font.Normal
                    font.variableAxes: ({ "wght": 400 })
                    font.letterSpacing: 1.536 * root.s
                    renderType: Text.NativeRendering
                    cursorDelegate: Caret {
                        s: root.s
                        on: nameInput.activeFocus
                        color: nameInput.color
                    }
                    Keys.onPressed: event => root.keyPressed(event, "name")
                }
            }

            // --- the password ----------------------------------------------------------------------
            Rectangle {
                id: field
                width: parent.width
                height: root.fieldH
                color: pw.activeFocus ? Tokens.color.darkGray : root.fieldRest
                readonly property color ink: pw.activeFocus ? Tokens.color.lightYellow : Tokens.color.darkGray

                Label {
                    x: root.u(24.96)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pw.text === ""
                    s: root.s
                    size: 18.24
                    spacing: 1.92
                    weight: Font.Normal
                    color: pw.activeFocus ? Tokens.color.lightGray : Tokens.color.mediumGray
                    text: "Password"
                }

                // the squares' window, inside the field's padding
                Item {
                    id: win
                    x: root.fieldPad
                    width: parent.width - 2 * root.fieldPad
                    height: parent.height
                    clip: true

                    Squares {
                        id: squares
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        count: pw.text.length
                        color: field.ink
                        window: win.width
                        focused: pw.activeFocus
                    }
                }

                // past the width: an ellipsis over the oldest squares
                Item {
                    width: root.u(61.44)
                    height: parent.height
                    opacity: squares.over ? 1 : 0
                    Behavior on opacity {
                        enabled: !Tokens.instant
                        NumberAnimation { duration: 120 }
                    }
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: field.color }
                            GradientStop { position: 0.55; color: field.color }
                            GradientStop { position: 1; color: Qt.rgba(field.color.r, field.color.g, field.color.b, 0) }
                        }
                    }
                    Label {
                        x: root.u(15.36)
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        size: 20.16
                        weight: Font.Bold
                        color: field.ink
                        text: "…"
                    }
                }

                TextInput {
                    id: pw
                    anchors.fill: parent
                    opacity: 0
                    focus: true
                    readOnly: root.locked
                    echoMode: TextInput.Password
                    cursorVisible: false
                    Keys.onPressed: event => root.keyPressed(event, "password")
                }
            }

            // --- the message line: the error or a notice, or the ring while the SDDM checks -----------
            Item {
                width: parent.width
                height: root.u(24.96)

                LoadingRing {
                    visible: root.busy
                    running: root.busy
                    width: parent.height
                    height: parent.height
                }
                Label {
                    visible: !root.busy
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    elide: Text.ElideRight
                    s: root.s
                    size: 18.24
                    spacing: 1.536
                    weight: Font.Normal
                    color: root.error ? Tokens.color.alert : Tokens.color.mediumGray
                    text: root.message
                }
            }
        }
    }

    // --- the text caret: .12 × 1.4 cqw, blinking once a second while its field has the focus --------
    component Caret: Rectangle {
        id: caret
        property real s: 1
        property bool on: false
        property bool lit: true
        width: Math.max(1, Tokens.px(2.3, s))
        height: Tokens.px(26.88, s)
        opacity: on && lit ? 1 : 0
        onOnChanged: { lit = true; blink.restart(); }
        Timer {
            id: blink
            interval: 500
            repeat: true
            running: caret.on && !Tokens.instant
            onTriggered: caret.lit = !caret.lit
        }
    }

    // --- the password's squares --------------------------------------------------------------------
    component Squares: Row {
        id: row
        property real s: 1
        property int count: 0
        property color color
        property real window: 0
        property bool focused: false

        readonly property int sq: Tokens.px(18.24, s)
        readonly property int lineH: Tokens.px(26.88, s)     // the caret's height; squares center on it
        readonly property int gapW: Tokens.px(8.64, s)
        readonly property int slot: sq + gapW
        // the live squares (not the ones on their way out)
        property int live: 0
        readonly property real used: live * slot + caretItem.width
        readonly property real shift: Math.max(0, used - window)
        readonly property bool over: shift > 0
        property int nextKey: 0

        x: -shift
        Behavior on x {
            enabled: !Tokens.instant
            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
        }

        onCountChanged: sync()
        function sync(): void {
            let k = 0;
            while (live < count) {
                model.append({ key: nextKey++, delay: Math.min(k, 12) * 18, out: false, gone: false });
                live++;
                k++;
            }
            while (live > count) {
                for (let i = model.count - 1; i >= 0; i--) {
                    const e = model.get(i);
                    if (!e.out && !e.gone) {
                        model.setProperty(i, "out", true);
                        break;
                    }
                }
                live--;
            }
        }
        function clearAll(animated: bool): void {
            live = 0;
            if (!animated || Tokens.instant) {
                model.clear();
                return;
            }
            for (let i = 0; i < model.count; i++)
                model.setProperty(i, "gone", true);
            sweepGone.restart();
        }
        function removeGone(): void {
            for (let i = model.count - 1; i >= 0; i--)
                if (model.get(i).gone)
                    model.remove(i);
        }
        function removeKey(key: int): void {
            for (let i = 0; i < model.count; i++)
                if (model.get(i).key === key) {
                    model.remove(i);
                    return;
                }
        }

        property ListModel model: ListModel {}
        property Timer sweepGone: Timer {
            interval: 150
            onTriggered: row.removeGone()
        }

        Repeater {
            model: row.model

            Item {
                id: cell
                required property int key
                required property int delay
                required property bool out
                required property bool gone
                property real fold: 1
                width: row.slot * fold
                height: row.lineH

                Rectangle {
                    id: box
                    y: Math.round((row.lineH - row.sq) / 2)
                    width: row.sq
                    height: row.sq
                    color: row.color
                    transform: Scale {
                        id: scale
                        origin.x: box.width / 2
                        origin.y: box.height / 2
                    }
                }

                // pop in: 0 → 1.35 → 1 in 160 ms, ease-out (a paste ripples in, 18 ms apart)
                SequentialAnimation {
                    id: popIn
                    PauseAnimation { duration: cell.delay }
                    NumberAnimation { target: scale; properties: "xScale,yScale"; from: 0; to: 1.35; duration: 88; easing.type: Easing.OutQuad }
                    NumberAnimation { target: scale; properties: "xScale,yScale"; to: 1; duration: 72; easing.type: Easing.OutQuad }
                }
                // Backspace: shrink and fold the slot in 90 ms, ease-in, then go
                SequentialAnimation {
                    id: shrink
                    ParallelAnimation {
                        NumberAnimation { target: scale; properties: "xScale,yScale"; to: 0; duration: 90; easing.type: Easing.InQuad }
                        NumberAnimation { target: cell; property: "fold"; to: 0; duration: 90; easing.type: Easing.InQuad }
                    }
                    ScriptAction { script: row.removeKey(cell.key) }
                }
                // a clear: fold away vertically and fade in 140 ms
                ParallelAnimation {
                    id: fade
                    NumberAnimation { target: scale; property: "yScale"; to: 0; duration: 140; easing.type: Easing.InQuad }
                    NumberAnimation { target: box; property: "opacity"; to: 0; duration: 140; easing.type: Easing.InQuad }
                }

                Component.onCompleted: {
                    if (Tokens.instant)
                        return;
                    scale.xScale = 0;
                    scale.yScale = 0;
                    popIn.start();
                }
                onOutChanged: {
                    if (!out)
                        return;
                    popIn.stop();
                    if (Tokens.instant)
                        row.removeKey(key);
                    else
                        shrink.start();
                }
                onGoneChanged: {
                    if (!gone)
                        return;
                    popIn.stop();
                    shrink.stop();
                    fade.start();
                }
            }
        }

        Caret {
            id: caretItem
            s: row.s
            on: row.focused
            color: row.color
        }
    }
}
