pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import "."

// Port of shell/ds/base/ListItem.qml for the SDDM greeter (spec 011, research R3). Same band, ink
// sweep, rails, box shadow and Pod selector; the sizes are parameters, because the login uses the
// approved mockup's rows (v3.2): users (48 px band, 14.4 px square, 21.1 px text, a light band at
// rest), the option rows (44.2 px, transparent or a faint ink band at rest).
//   selected: the parent's choice (keys, click); hoverInks: the pointer inks the row too (options).
//   Inked: the ink band, its rails (2 px, 5 px above and below) and its box shadow sweep in from the
//   left together in Tokens.motion.highlight; leaving is instant. The label wipes from ink to light
//   with the band. The selector hangs to the left at x = -selectorRoom; the parent keeps that room.
//   value / arrows: a right-aligned value, between ◂ and ▸ that show while the row is inked.
// `interactive: false` makes it ignore the pointer (the greeter is not ready, FR-021).
Item {
    id: root

    property real s: 1
    property string text
    property bool selected: false
    property bool hoverInks: false
    property bool interactive: true
    property color rest: "transparent"
    property real bandSize: Tokens.space.listItemH
    property real padSize: 17.28                 // band edge → square, value → edge
    property real gapSize: 13.44                 // square → label, label → value
    property real squareSize: 14.4
    property real textSize: 21.12
    property real textSpacing: 1.536
    property int textWeight: Font.Medium
    property string value: ""
    property bool arrows: false
    property real valueMinW: 115.2               // the value's slot between the arrows

    readonly property bool hovered: interactive && mouse.containsMouse
    readonly property bool inked: selected || (hoverInks && hovered)
    readonly property int selectorRoom: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, s)

    signal clicked()
    signal stepped(int d)

    readonly property int bandH: Tokens.px(bandSize, s)
    readonly property int pad: Tokens.px(padSize, s)
    readonly property int gap: Tokens.px(gapSize, s)
    readonly property int sq: Tokens.px(squareSize, s)
    readonly property int rail: Tokens.line(Tokens.space.rail, s)
    readonly property int railGap: Tokens.px(Tokens.space.railGap, s)
    // ◂ value ▸: two 23 × 38 px buttons around a slot at least valueMinW wide, 3.8 px apart.
    readonly property int arrowW: Tokens.px(23.04, s)
    readonly property int arrowH: Tokens.px(38.4, s)
    readonly property int valueGap: Tokens.px(3.84, s)
    readonly property int valueW: value === "" ? 0
        : (arrows ? 2 * (arrowW + valueGap) : 0) + Math.max(Tokens.px(valueMinW, s), Math.ceil(dark.valueWidth))

    implicitHeight: bandH

    // Ink sweep, as in the shell's ListItem.
    property real sweep: 0
    readonly property real fill: Tokens.instant ? (inked ? 1 : 0) : sweep
    readonly property int inkW: Math.round(width * fill)
    onInkedChanged: {
        sweepAnim.stop();
        if (inked && !Tokens.instant)
            sweepAnim.start();
        else
            sweep = inked ? 1 : 0;
    }
    Component.onCompleted: sweep = inked ? 1 : 0

    NumberAnimation {
        id: sweepAnim
        target: root
        property: "sweep"
        from: 0
        to: 1
        duration: Tokens.motion.highlight
        easing.type: Easing.OutCubic
    }

    component Face: Item {
        id: face
        property color ink
        readonly property real valueWidth: valueText.implicitWidth
        width: root.width
        height: root.bandH
        Rectangle {
            x: root.pad
            anchors.verticalCenter: parent.verticalCenter
            width: root.sq
            height: root.sq
            color: face.ink
        }
        Label {
            x: root.pad + root.sq + root.gap
            width: Math.max(0, root.width - x - root.pad - (root.valueW > 0 ? root.gap + root.valueW : 0))
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            size: root.textSize
            weight: root.textWeight
            spacing: root.textSpacing
            text: root.text
            elide: Text.ElideRight
            color: face.ink
        }
        Item {
            visible: root.value !== ""
            x: root.width - root.pad - root.valueW
            width: root.valueW
            height: parent.height
            Arrow {
                visible: root.arrows && root.inked
                x: 0
                pointsLeft: true
                color: face.ink
            }
            Label {
                id: valueText
                x: root.arrows ? root.arrowW + root.valueGap : 0
                width: root.valueW - (root.arrows ? 2 * (root.arrowW + root.valueGap) : 0)
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                s: root.s
                size: root.textSize
                weight: root.textWeight
                spacing: root.textSpacing
                text: root.value
                color: face.ink
            }
            Arrow {
                visible: root.arrows && root.inked
                x: root.valueW - root.arrowW
                pointsLeft: false
                color: face.ink
            }
        }
    }

    // A small solid triangle (9.6 × 13.4 game px) centered in a 23 × 38 button, pointing left or right.
    component Arrow: Item {
        id: arrow
        property bool pointsLeft
        property color color
        width: root.arrowW
        height: root.arrowH
        anchors.verticalCenter: parent.verticalCenter
        Shape {
            id: tri
            readonly property real w: 9.6 * root.s
            readonly property real h: 13.44 * root.s
            x: Math.round((arrow.width - w) / 2)
            y: Math.round((arrow.height - h) / 2)
            width: w
            height: h
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: arrow.color
                strokeWidth: -1
                startX: arrow.pointsLeft ? tri.w : 0
                startY: 0
                PathLine { x: arrow.pointsLeft ? 0 : tri.w; y: tri.h / 2 }
                PathLine { x: arrow.pointsLeft ? tri.w : 0; y: tri.h }
                PathLine { x: arrow.pointsLeft ? tri.w : 0; y: 0 }
            }
        }
    }

    // box shadow, under everything
    Rectangle {
        x: Tokens.px(Tokens.shadow.boxX, root.s)
        y: Tokens.px(Tokens.shadow.boxY, root.s)
        width: root.inkW
        height: root.bandH
        visible: root.inkW > 0
        color: Tokens.color.boxShadow
    }

    Rectangle {
        width: root.width
        height: root.bandH
        visible: root.rest.a > 0
        color: root.rest
    }

    Face {
        id: dark
        ink: Tokens.color.darkGray
    }

    // rails
    Repeater {
        model: [-1, 1]
        Rectangle {
            required property int modelData
            y: modelData < 0 ? -root.railGap - root.rail : root.bandH + root.railGap
            width: root.inkW
            height: root.rail
            visible: root.inkW > 0
            color: Tokens.color.darkGray
        }
    }

    Rectangle {
        width: root.inkW
        height: root.bandH
        visible: root.inkW > 0
        clip: true
        color: Tokens.color.darkGray

        Face { ink: Tokens.color.lightYellow }
    }

    Selector {
        x: -root.selectorRoom
        y: Math.round((root.bandH - height) / 2)
        s: root.s
        shown: root.inked
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // The arrows' buttons, over the row: a click there steps the value instead.
    Repeater {
        model: root.arrows && root.value !== "" ? [-1, 1] : []
        MouseArea {
            required property int modelData
            x: modelData < 0 ? root.width - root.pad - root.valueW : root.width - root.pad - root.arrowW
            y: Math.round((root.bandH - root.arrowH) / 2)
            width: root.arrowW
            height: root.arrowH
            enabled: root.interactive
            cursorShape: Qt.PointingHandCursor
            onClicked: root.stepped(modelData)
        }
    }
}
