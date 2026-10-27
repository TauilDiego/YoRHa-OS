pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"

// The game's tab bar: the double vertical strips, one HeaderButton per tab, each with the
// selector's room before it, and the dotted rule underneath. The selected tab reaches the rule.
//   model: [{ label, state }], state = "normal" | "hovered" | "selected" | "dimmed".
// The parent owns the states: map `hoveredIndex` into the model to show the hover.
// The rule spans the bar's whole width; the tabs start at the left.
Item {
    id: root

    property real s: 1
    property var model: []
    property real ruleGap: 10                    // game px between the tabs and the rule
    property real ruleScale: s                   // scale of the rule's dotted pattern

    // Index of the tab under the pointer, or -1.
    readonly property int hoveredIndex: hover.index
    QtObject {
        id: hover
        property int index: -1
    }

    signal activated(int index)

    readonly property int bandH: Tokens.px(Tokens.space.tabH, s)
    readonly property int ruleY: bandH + Tokens.px(ruleGap, s)
    readonly property int stripGap: Tokens.px(10, s)

    implicitWidth: row.x + row.implicitWidth
    implicitHeight: ruleY + rule.implicitHeight

    Rule {
        id: strips
        kind: "vertical"
        s: root.s
        height: root.bandH
    }

    Row {
        id: row
        x: strips.implicitWidth + root.stripGap
        // The selector hangs at x = -selectorRoom: keep that room free before every tab.
        readonly property int room: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, root.s)
        leftPadding: room
        spacing: room

        // The model is indexed, not handed to the Repeater: a new array with the same length
        // (e.g. a hover change) keeps the delegates, so the pointer never loses its tab.
        Repeater {
            id: tabs
            model: Array.isArray(root.model) ? root.model.length : 0

            HeaderButton {
                required property int index
                readonly property var entry: root.model[index] ?? ({})

                s: root.s
                text: entry.label ?? ""
                state: entry.state ?? "normal"
                reachRule: true
                ruleY: root.ruleY
                onClicked: root.activated(index)
                onHoveredChanged: {
                    if (hovered)
                        hover.index = index;
                    else if (hover.index === index)
                        hover.index = -1;
                }
                Component.onDestruction: if (hover.index === index) hover.index = -1
            }
        }
    }

    Rule {
        id: rule
        kind: "dotted"
        y: root.ruleY
        s: root.ruleScale
        width: root.width
    }
}
