pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."
import "../primitives"
import "../base"
import "../../strings"

// Option row (spec 003): a plain ListItem with the option's value on its right, by type
// (research R10):
//   toggle  ◂ ON ▸ / ◂ OFF ▸        choice  ◂ value ▸ (ValueStepper; the end arrow fades)
//   slider  editable Meter + number  action  label + arrow      info  read-only text
// `focused`: the ink band and the dark kite; the arrows show, and the value turns light when the
// band's sweep reaches it. `dimmed` (it needs a toggle that is off): the 001 dimmed state; with
// the focus, the band and the kite with the light text at 55%. A dimmed row never emits
// stepped/picked. Clicks: an arrow → stepped(∓1), the slider's track → picked(0–1), anywhere
// else → activated().
//   option: an option of the settings catalog (data-model); value: its current value.
// spec 004: `contentScale` draws the label, the square and the value smaller on the same band,
// rails and kite (the wallpaper picker's Options card).
// spec 008: `valueWidth` (game px) is the text's width between ◂ and ▸ of a toggle or a choice;
// Tokens.space.stepperValueW by default (the text log narrows its toggle's).
// spec 013 (front A): the row moves as its ListItem (selection, pulse, the cascade's enter() and
// leave(), FR-001/002/005/008), its value with it: wiped in by the same edge, faded by the same
// level. enterLevel(delay) is the game's sublist entry (FR-008): a fade and a levelDx slide from
// the left over levelIn, after `delay` ms.
Item {
    id: root

    property real s: 1
    property var option: ({})
    property var value: null
    property bool dimmed: false
    property bool focused: false
    property real contentScale: 1
    property real valueWidth: Tokens.space.stepperValueW
    readonly property real cs: s * contentScale
    readonly property bool hovered: item.hovered
    readonly property Item valueItem: type === "slider" ? meter : stepper.visible ? stepper : null

    signal stepped(int dir)
    signal picked(real value)
    signal activated()

    // spec 013: the row's motion is its ListItem's; the value follows the wipe's edge.
    readonly property string motionRow: "option"
    readonly property real wipeX: item.reveal >= 1 ? width + item.shadowX : (width + item.shadowX) * item.reveal
    function enter(delay: int, kiteAt: int): int {
        return item.enter(delay, kiteAt);
    }
    function complete(): void {
        item.complete();
    }
    function leave(): void {
        item.leave();
    }
    function restore(): void {
        item.restore();
    }
    function holdKite(): void {
        item.holdKite();
    }

    property real arrive: 1
    opacity: arrive
    transform: Translate { x: -Math.round((1 - root.arrive) * Tokens.motion.levelDx * root.s) }
    function enterLevel(delay: int): void {
        arriveAnim.stop();
        if (Tokens.instant) {
            arrive = 1;
            return;
        }
        arrive = 0;
        arrivePause.duration = Math.max(0, delay);
        arriveAnim.start();
    }
    SequentialAnimation {
        id: arriveAnim
        PauseAnimation { id: arrivePause }
        NumberAnimation {
            target: root
            property: "arrive"
            from: 0
            to: 1
            duration: Tokens.motion.levelIn
            easing.type: Easing.OutQuart
        }
    }

    readonly property string type: String(option?.type ?? "info")
    readonly property bool stepping: type === "toggle" || type === "choice"
    readonly property string valueText: {
        switch (type) {
        case "toggle":
            return value ? Strings.settings.on : Strings.settings.off;
        case "choice":
            return String(option.values?.[value] ?? "");
        case "slider":
            return value === null || value === undefined ? "" : String(value);
        }
        return String(option?.text ?? "");
    }

    readonly property int gap: Tokens.px(16, cs)
    // Free text values (action, info) take at most this share of the row; an action's arrow
    // (11 px + 12 px before it) comes on top of its text.
    readonly property real textShare: 0.45
    readonly property int arrowRoom: type === "action" ? Tokens.px(11, cs) + Tokens.px(12, cs) : 0
    readonly property int numberW: Tokens.px(46, cs)         // the slider's number

    implicitWidth: Tokens.px(Tokens.space.settingsOptsW, s)     // the parent sets the width
    implicitHeight: item.implicitHeight

    ListItem {
        id: item
        width: root.width
        s: root.s
        contentScale: root.contentScale
        variant: "plain"
        text: String(root.option?.label ?? "")
        reserve: valueBox.width + root.gap + pad
        state: root.focused ? "hovered" : root.dimmed ? "dimmed" : "normal"
        onClicked: root.activated()
    }

    // Dimmed + focused: an ink veil over the band leaves its light text at 55%, as in the mockup.
    // Same geometry as the band, so their edges round together at fractional scales.
    Rectangle {
        width: item.inkW
        height: item.bandH
        visible: root.focused && root.dimmed && width > 0 && item.reveal >= 1
        opacity: item.bandLevel
        color: Qt.rgba(Tokens.color.darkGray.r, Tokens.color.darkGray.g, Tokens.color.darkGray.b, 0.45)
    }

    // The value turns light once the band's sweep has passed its middle.
    readonly property bool inked: item.inkW > 0 && item.inkW >= valueBox.x + valueBox.width / 2
    readonly property color light: Tokens.color.lightYellow
    readonly property color ink: !inked ? (dimmed ? Tokens.color.mediumGray : Tokens.color.darkGray)
                                        : (dimmed ? Qt.rgba(light.r, light.g, light.b, 0.55) : light)

    // The free text at its natural width, never shown: sizing from the shown, elided label
    // would feed its width back into itself.
    Label {
        id: freeMeasure
        visible: false
        s: root.cs
        role: "standard"
        font.weight: Font.Medium
        font.variableAxes: ({ "wght": Font.Medium })
        text: root.valueText
    }

    Item {
        id: valueBox
        x: root.width - item.pad - width
        // From tokens only: reading the children's sizes here makes a binding loop while a
        // delegate is being set up.
        width: root.type === "slider" ? Tokens.px(Tokens.space.sliderW, root.cs) + Tokens.px(16, root.cs) + root.numberW
             : root.stepping ? 2 * (Tokens.px(11, root.cs) + Tokens.px(14, root.cs)) + Tokens.px(root.valueWidth, root.cs)
             : Math.min(Math.ceil(freeMeasure.implicitWidth) + root.arrowRoom, Math.round(root.width * root.textShare))
        height: item.bandH
        opacity: item.textLevel

        // spec 013: the value shows as the row's wipe passes it.
        Item {
            width: Math.max(0, Math.min(valueBox.width, root.wipeX - valueBox.x))
            height: valueBox.height
            visible: width > 0
            clip: width < valueBox.width

            Item {
                width: valueBox.width
                height: valueBox.height

                ValueStepper {
                    id: stepper
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.stepping
                    s: root.cs
                    valueWidth: root.valueWidth
                    text: root.valueText
                    ink: root.ink
                    arrows: root.focused
                    atStart: root.type === "choice" && root.value === 0
                    atEnd: root.type === "choice" && root.value === (root.option?.values?.length ?? 0) - 1
                    onStepped: dir => {
                        if (!root.dimmed)
                            root.stepped(dir);
                    }
                }

                Row {
                    id: slider
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.type === "slider"
                    spacing: Tokens.px(16, root.cs)

                    Meter {
                        id: meter
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.cs
                        w: Tokens.space.sliderW
                        value: Number(root.value ?? 0) / 100
                        editable: !root.dimmed
                        inverted: root.inked
                        onPicked: v => root.picked(v)
                    }
                    Label {
                        width: root.numberW
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.cs
                        role: "standard"
                        font.weight: Font.Medium
                        font.variableAxes: ({ "wght": Font.Medium })
                        font.features: ({ "tnum": 1 })
                        horizontalAlignment: Text.AlignRight
                        text: root.valueText
                        color: root.ink
                    }
                }

                // action: label + arrow; info: read-only text, mediumGray (light at 75% on the band).
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.stepping && root.type !== "slider"
                    spacing: Tokens.px(12, root.cs)

                    Label {
                        id: free
                        width: Math.min(Math.ceil(freeMeasure.implicitWidth), valueBox.width - root.arrowRoom)
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.cs
                        role: "standard"
                        font.weight: Font.Medium
                        font.variableAxes: ({ "wght": Font.Medium })
                        elide: Text.ElideRight
                        text: root.valueText
                        color: root.type === "info"
                            ? (root.inked ? Qt.rgba(root.light.r, root.light.g, root.light.b, 0.75) : Tokens.color.mediumGray)
                            : root.ink
                    }
                    Shape {
                        id: arrow
                        visible: root.type === "action"
                        anchors.verticalCenter: parent.verticalCenter
                        width: Tokens.px(11, root.cs)
                        height: Tokens.px(16, root.cs)
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: root.ink
                            strokeWidth: -1
                            startX: 0
                            startY: 0
                            PathLine { x: arrow.width; y: arrow.height / 2 }
                            PathLine { x: 0; y: arrow.height }
                            PathLine { x: 0; y: 0 }
                        }
                    }
                }
            }
        }
    }
}
