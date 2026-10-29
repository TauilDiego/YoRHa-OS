pragma ComponentBehavior: Bound

import QtQuick
import "../../ds"
import "../../ds/primitives"
import "../../ds/base"
import "../../notify"
import "../../strings"

// The gallery's page 5 (spec 008, FR-044, SC-016): the text log's body (LogPage) in the two hosts it
// has, side by side at the same scale, each on a paper card of its body's size: the pop-up's (the
// whole 1612 × 908 frame; the page keeps the room of the frame's title and footer) and the pause
// menu's (spec 007: the same frame, the body from y 221 to 24 px above the footer rule). Nothing
// there takes the keyboard. The entries are NotifyStore's (the fixture, in the lab).
Rectangle {
    id: root

    property real s: 1
    property real dpr: 1

    readonly property var gs: Strings.gallery
    readonly property real k: 0.52                     // the bodies' scale on the page
    readonly property real popupBodyH: Tokens.space.popupH
    readonly property real pauseBodyH: Tokens.space.popupH - 221 - (Tokens.space.popupH - 820) - 24

    function u(v: real): int {
        return Tokens.px(v, s);
    }

    color: Tokens.color.darkYellow

    PageHeader {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(Tokens.space.pageMarginV)
        s: root.s
        title: root.gs.title
        subtitle: root.gs.page5Subtitle
    }
    Rule {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(128)
        width: parent.width - 2 * x
        s: root.s
    }

    component Host: Column {
        id: host
        property string name
        property string kind
        property real bodyH
        spacing: root.u(10)
        Label {
            s: root.s
            role: "small"
            text: host.name
        }
        Rectangle {
            width: root.u(Tokens.space.popupW * root.k)
            height: root.u(host.bodyH * root.k)
            color: Tokens.color.lightYellow
            border.width: Tokens.line(1, root.s)
            border.color: Tokens.color.darkGray
            clip: true
            LogPage {
                anchors.fill: parent
                s: root.s * root.k
                dpr: root.dpr
                host: host.kind
                focus: false
                active: false
            }
        }
    }

    Row {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(160)
        spacing: root.u(40)
        Host {
            name: root.gs.logPopup
            kind: "popup"
            bodyH: root.popupBodyH
        }
        Host {
            name: root.gs.logPause
            kind: "pause"
            bodyH: root.pauseBodyH
        }
    }
}
