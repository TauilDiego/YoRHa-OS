pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"
import "../../strings"

// Status card (design-system §4, spec 007): the game's "Status" box as a headered Card with the
// light mark. From the top of its body:
//   label/value pairs: the label in ink on the left, the value on the right (tabular figures), with
//                      a Meter (statusMeterW × 11) before the value when the row has `meter` (0–1);
//   a light-gray rule;
//   a row of `boxes` empty squares (statusBox, a 2 px medium-gray border);
//   a centered footer: NO ERROR (small, letter spacing 3), or `note` in alert.
//   rows: [{ label, value, meter }] (`meter` 0–1, or null for none).
// The parent sets the width; the height follows the content.
Item {
    id: root

    property real s: 1
    property string title: Strings.pause.status
    property var rows: []
    property int boxes: 6
    property string note: ""

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    readonly property int margin: card.margin
    readonly property int rowGap: u(16)
    readonly property int meterGap: u(12)

    implicitWidth: u(Tokens.space.pickerOptionsW)
    implicitHeight: footer.y + footer.height + u(26)

    Card {
        id: card
        anchors.fill: parent
        s: root.s
        mark: true
        title: root.title
    }

    Column {
        id: rowColumn
        x: root.margin
        y: card.headerH + root.u(22)
        width: root.width - 2 * root.margin
        spacing: root.rowGap

        Repeater {
            id: rowRepeater
            model: root.rows

            Item {
                id: row
                required property var modelData
                readonly property bool hasMeter: typeof modelData?.meter === "number" && isFinite(modelData.meter)
                width: rowColumn.width
                height: Math.max(label.implicitHeight, valueText.implicitHeight)

                Label {
                    id: label
                    width: Math.max(0, (row.hasMeter ? meter.x - root.meterGap : valueText.x - root.meterGap))
                    s: root.s
                    role: "standard"
                    font.weight: Font.Medium
                    font.variableAxes: ({ "wght": Font.Medium })
                    upper: true
                    elide: Text.ElideRight
                    text: String(row.modelData?.label ?? "")
                }
                Meter {
                    id: meter
                    x: valueText.x - root.meterGap - width
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.hasMeter
                    s: root.s
                    w: Tokens.space.statusMeterW
                    value: row.hasMeter ? row.modelData.meter : 0
                }
                Label {
                    id: valueText
                    x: row.width - width
                    width: Math.min(implicitWidth, row.width * 0.6)
                    s: root.s
                    role: "standard"
                    font.features: ({ "tnum": 1 })
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: String(row.modelData?.value ?? "")
                }
            }
        }
    }

    Rectangle {
        id: rule
        x: root.margin
        y: rowColumn.y + rowColumn.height + root.u(22)
        width: root.width - 2 * root.margin
        height: Tokens.line(Tokens.space.rule, root.s)
        color: Tokens.color.lightGray
    }

    Row {
        id: boxRow
        x: root.margin
        y: rule.y + rule.height + root.u(20)
        spacing: root.u(12)

        Repeater {
            model: Math.max(0, root.boxes)

            Rectangle {
                width: root.u(Tokens.space.statusBox)
                height: width
                color: "transparent"
                border.width: Tokens.line(2, root.s)
                border.color: Tokens.color.mediumGray
            }
        }
    }

    Label {
        id: footer
        x: root.margin
        y: boxRow.y + boxRow.height + root.u(22)
        width: root.width - 2 * root.margin
        s: root.s
        role: "small"
        font.letterSpacing: (root.note === "" ? 3 : 1) * root.s
        font.weight: Font.DemiBold
        font.variableAxes: ({ "wght": Font.DemiBold })
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        maximumLineCount: 3
        elide: Text.ElideRight
        text: root.note === "" ? Strings.pause.noError : root.note
        color: root.note === "" ? Tokens.color.darkGray : Tokens.color.alert
    }
}
