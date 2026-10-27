pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import ".."
import "../primitives"

// Value stepper (spec 003): "◂ value ▸", the value of a toggle or a choice. The arrows only show
// with `arrows` (the focused row) but always keep their room; at an end of the list its arrow
// fades to 30%. A click on an arrow emits stepped(-1 / +1). The text is centered in
// Tokens.space.stepperValueW and cut with an ellipsis when it is longer.
Item {
    id: root

    property real s: 1
    property string text
    property color ink: Tokens.color.darkGray
    property bool arrows: false
    property bool atStart: false
    property bool atEnd: false

    signal stepped(int dir)

    readonly property int arrowW: Tokens.px(11, s)       // the mockup's triangles: 11 × 16
    readonly property int arrowH: Tokens.px(16, s)
    readonly property int gap: Tokens.px(14, s)
    readonly property int valueW: Tokens.px(Tokens.space.stepperValueW, s)

    implicitWidth: 2 * (arrowW + gap) + valueW
    implicitHeight: Math.max(arrowH, label.implicitHeight)

    // A flat triangle pointing left (dir -1) or right (dir 1), with a hit area as tall as the row.
    component Arrow: Item {
        id: arrow
        property int dir: 1
        property bool end: false
        width: root.arrowW + root.gap
        height: root.height

        Shape {
            x: arrow.dir < 0 ? 0 : root.gap
            y: Math.round((root.height - root.arrowH) / 2)
            width: root.arrowW
            height: root.arrowH
            visible: root.arrows
            opacity: arrow.end ? 0.3 : 1
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: root.ink
                strokeWidth: -1
                startX: arrow.dir < 0 ? root.arrowW : 0
                startY: 0
                PathLine { x: arrow.dir < 0 ? 0 : root.arrowW; y: root.arrowH / 2 }
                PathLine { x: arrow.dir < 0 ? root.arrowW : 0; y: root.arrowH }
                PathLine { x: arrow.dir < 0 ? root.arrowW : 0; y: 0 }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.arrows
            cursorShape: Qt.PointingHandCursor
            onClicked: root.stepped(arrow.dir)
        }
    }

    Arrow {
        dir: -1
        end: root.atStart
    }

    Label {
        id: label
        x: root.arrowW + root.gap
        width: root.valueW
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        role: "standard"
        font.weight: Font.Medium                     // the mockup's values: 23 px, weight 500
        font.variableAxes: ({ "wght": Font.Medium })
        font.features: ({ "tnum": 1 })
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.text
        color: root.ink
    }

    Arrow {
        x: root.width - width
        dir: 1
        end: root.atEnd
    }
}
