pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"

// The game's tab bar: the double vertical strips, the HeaderButtons side by side, and the
// dotted rule underneath. The selected tab reaches the rule.
//   model: [{ label, state }], state = "normal" | "hovered" | "selected" | "dimmed".
// The parent owns the states: map `hoveredIndex` into the model to show the hover.
// The rule spans the bar's whole width; the tabs start at the left.
// `tone` (spec 004 US6): the top bar's tone, 0 paper → 1 light, handed to strips, tabs and rule.
// `high` (004 acabamento): the bar's High contrast, handed to the tabs.
Item {
    id: root

    property real s: 1
    property real tone: 0
    property bool high: false
    property var model: []
    property real ruleGap: 10                    // game px between the tabs and the rule
    property real ruleScale: s                   // scale of the rule's dotted pattern

    // Index of the tab under the pointer, or -1.
    readonly property int hoveredIndex: hover.index
    QtObject {
        id: hover
        property int index: -1
        // Which tab is under the pointer, from scratch. Called deferred (Qt.callLater): `model`
        // reads hoveredIndex, and tabs come and go while it is re-evaluated, so a synchronous
        // write is a binding loop. As a method of this object, a call still queued when the bar
        // is torn down (live reload, monitor change) is dropped by Qt; and since it recomputes
        // everything, several calls coalesced into one lose nothing.
        function sync(): void {
            let h = -1;
            for (let i = 0; i < tabs.count; i++) {
                const t = tabs.itemAt(i) as HeaderButton;
                if (t && t.hovered) {
                    h = i;
                    break;
                }
            }
            index = h;
        }
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
        tone: root.tone
        height: root.bandH
    }

    Row {
        id: row
        x: strips.implicitWidth + root.stripGap
        spacing: Tokens.px(10, root.s)               // 10 game px between tabs (bar A2)

        // The model is indexed, not handed to the Repeater: a new array with the same length
        // (e.g. a hover change) keeps the delegates, so the pointer never loses its tab.
        Repeater {
            id: tabs
            model: Array.isArray(root.model) ? root.model.length : 0

            HeaderButton {
                required property int index
                readonly property var entry: root.model[index] ?? ({})

                s: root.s
                tone: root.tone
                high: root.high
                text: entry.label ?? ""
                state: entry.state ?? "normal"
                reachRule: true
                ruleY: root.ruleY
                onClicked: root.activated(index)
                onHoveredChanged: Qt.callLater(hover.sync)
                Component.onDestruction: Qt.callLater(hover.sync)
            }
        }
    }

    Rule {
        id: rule
        kind: "dotted"
        y: root.ruleY
        s: root.ruleScale
        tone: root.tone
        width: root.width
    }
}
