pragma ComponentBehavior: Bound

import QtQuick
import "../ds"

// Session, Reboot and Shut down as option rows under the card (spec 011 FR-013, FR-014; mockup v3.2
// "#acts"). The pointer inks a row and brings the kite; the session's ◂ ▸ show while its row is
// inked. A click on Session steps it forward, on an arrow steps it that way.
Column {
    id: root

    property real s: 1
    property string session: ""
    property bool interactive: true

    signal sessionStep(int d)
    signal reboot()
    signal shutdown()

    spacing: Tokens.px(Tokens.space.listItemGap, s)

    component Act: ListItem {
        width: root.width
        s: root.s
        hoverInks: true
        interactive: root.interactive
        bandSize: 44.16
        squareSize: 13.44
        textSize: 19.2
        rest: Qt.rgba(78 / 255, 75 / 255, 66 / 255, 0.12)
    }

    Act {
        text: "Session"
        value: root.session
        arrows: true
        onClicked: root.sessionStep(1)
        onStepped: d => root.sessionStep(d)
    }
    Act {
        text: "Reboot"
        onClicked: root.reboot()
    }
    Act {
        text: "Shut down"
        onClicked: root.shutdown()
    }
}
