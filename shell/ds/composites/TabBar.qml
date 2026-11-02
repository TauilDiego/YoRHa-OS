pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"

// The game's tab bar: the double vertical strips, the HeaderButtons side by side, and the
// dotted rule underneath. The selected tab reaches the rule.
//   model: [{ label, state, tag }], state = "normal" | "hovered" | "selected" | "dimmed"; tag (spec
//   015, optional): an outline Tag on the tab (NEW), "" or absent = none.
// The parent owns the states: map `hoveredIndex` into the model to show the hover.
// The rule spans the bar's whole width; the tabs start at the left.
// `tone` (spec 004 US6): the top bar's tone, 0 paper → 1 light, handed to strips, tabs and rule.
// `high` (004 acabamento): the bar's High contrast, handed to the tabs.
// spec 013 (front A): `pulse` makes the selected tab breathe (FR-002, the pause menu). `buildT` is
// the ms into a menu's assembly (PopupFrame, E1), < 0 when there is none: the dotted rule draws
// itself from the right, then the strips and the tabs fade in, one after the other.
Item {
    id: root

    property real s: 1
    property real tone: 0
    property bool high: false
    property var model: []
    property real ruleGap: 10                    // game px between the tabs and the rule
    property real ruleScale: s                   // scale of the rule's dotted pattern
    property real tabWidth: 0                    // spec 007: game px per tab; 0 = fit the label
    property bool pulse: false                   // spec 013
    property real buildT: -1

    // spec 013: how far a part that starts at `start` and lasts `dur` is into the assembly (0–1).
    function level(start: real, dur: real): real {
        return buildT < 0 ? 1 : Math.max(0, Math.min(1, (buildT - start) / Math.max(1, dur)));
    }

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

    // Where tab `i` is, in window coordinates (logical px), for tests: { x, w, tag }.
    function tabGeometry(i: int): var {
        const tab = tabs.itemAt(i) as HeaderButton;
        if (!tab)
            return { x: -1, w: 0, tag: "" };
        const p = tab.mapToItem(null, 0, 0);
        return { x: Math.round(p.x), w: Math.round(tab.width), tag: tab.tag };
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
        opacity: root.level(Tokens.motion.buildStrips, Tokens.motion.buildFade)
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
                tag: entry.tag ?? ""
                state: entry.state ?? "normal"
                reachRule: true
                fixedWidth: root.tabWidth
                ruleY: root.ruleY
                pulse: root.pulse
                opacity: root.level(Tokens.motion.buildTabs + index * Tokens.motion.cascadeStep, Tokens.motion.buildFade)
                onClicked: root.activated(index)
                onHoveredChanged: Qt.callLater(hover.sync)
                Component.onDestruction: Qt.callLater(hover.sync)
            }
        }
    }

    // The rule, drawn from the right while the menu assembles (OutQuart).
    Item {
        readonly property real drawn: 1 - Math.pow(1 - root.level(0, Tokens.motion.buildRules), 4)
        x: Math.round(root.width * (1 - drawn))
        y: root.ruleY
        width: root.width - x
        height: rule.implicitHeight
        clip: drawn < 1
        visible: drawn > 0

        Rule {
            id: rule
            x: -parent.x
            kind: "dotted"
            s: root.ruleScale
            tone: root.tone
            width: root.width
        }
    }
}
