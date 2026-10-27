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
    property bool showSelector: true             // false: tabs side by side, no Pod cursor (HUD)

    // Index of the tab under the pointer, or -1.
    readonly property int hoveredIndex: hover.index
    QtObject {
        id: hover
        property int index: -1
    }

    signal activated(int index)

    // Where tab `i` is, in window coordinates (logical px), for tests: { x, w }.
    function tabGeometry(i: int): var {
        const tab = tabs.itemAt(i);
        if (!tab)
            return { x: -1, w: 0 };
        const p = tab.mapToItem(null, 0, 0);
        return { x: Math.round(p.x), w: Math.round(tab.width) };
    }

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
        // Without it the tabs sit side by side, 10 game px apart (bar A2).
        readonly property int room: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, root.s)
        leftPadding: root.showSelector ? room : 0
        spacing: root.showSelector ? room : Tokens.px(10, root.s)

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
                selectorTone: "dark"                 // the selector always hangs over the paper
                showSelector: root.showSelector
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
