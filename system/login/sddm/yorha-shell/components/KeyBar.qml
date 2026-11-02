pragma ComponentBehavior: Bound

import QtQuick
import "../ds"

// The key bar under the bottom rule's dots (spec 011 FR-007; mockup v3.2 ".keys", 1040–1080 game px):
// the hint on the left, the keys that work on the right, each an ink box with the key and a label.
Item {
    id: root

    property real s: 1
    property string hint: ""
    property var keys: [
        { key: "↑↓", label: "Select" },
        { key: "Enter", label: "Log in" },
        { key: "Tab", label: "Session" },
        { key: "Esc", label: "Clear" }
    ]

    Label {
        x: Tokens.px(65.28, root.s)
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        size: 18.24
        spacing: 1.536
        weight: Font.Normal
        color: Tokens.color.mediumGray
        text: root.hint
    }

    KeyHints {
        anchors.right: parent.right
        anchors.rightMargin: Tokens.px(65.28, root.s)
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        model: root.keys
    }
}
