import QtQuick
import "../ds"

// After the right password (spec 011 FR-016; mockup v3.2 ".welcome"): "Welcome, <user>" and the
// session, centered on the paper while the panels fade away.
Column {
    id: root

    property real s: 1
    property string user: ""
    property string session: ""

    spacing: Tokens.px(13.44, s)

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        s: root.s
        size: 38.4
        spacing: 7.68
        weight: Font.Bold
        text: "Welcome, " + root.user
    }
    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        s: root.s
        size: 17.28
        spacing: 5.76
        color: Tokens.color.mediumGray
        upper: true
        text: root.session
    }
}
