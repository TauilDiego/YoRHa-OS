pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"

// Key hints (spec 003): the keys that work right now, at the foot of a menu. Each hint is an ink
// box with the key (button style, light) and what it does (small, ink), as in the mockup.
//   model: a JS array of { key, label }.
// The parent places the row; it is usually anchored to the right.
Row {
    id: root

    property real s: 1
    property var model: []

    spacing: Tokens.px(34, s)

    Repeater {
        model: root.model

        Row {
            id: hint
            required property var modelData
            spacing: Tokens.px(12, root.s)

            Rectangle {
                width: Math.max(Tokens.px(34, root.s), Math.ceil(key.implicitWidth) + 2 * Tokens.px(8, root.s))
                height: Tokens.px(30, root.s)
                color: Tokens.color.darkGray

                Label {
                    id: key
                    anchors.centerIn: parent
                    s: root.s
                    role: "button"
                    text: String(hint.modelData?.key ?? "")
                    color: Tokens.color.lightYellow
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                role: "small"
                text: String(hint.modelData?.label ?? "")
            }
        }
    }
}
