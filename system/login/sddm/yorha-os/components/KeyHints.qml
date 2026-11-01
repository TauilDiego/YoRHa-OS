pragma ComponentBehavior: Bound

import QtQuick
import "../ds"

// One row of key hints (mockup v3.2 ".keys .k", ".dk"): each an ink box with the key, then what it
// does. The key bar and the confirmation dialog use it, with their own text size and gap.
Row {
    id: hints

    property real s: 1
    property var model: []
    property real textSize: 18.24
    property real gapSize: 30.72

    spacing: Tokens.px(gapSize, s)

    Repeater {
        model: hints.model

        Row {
            id: hint
            required property var modelData
            spacing: Tokens.px(8.64, hints.s)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.ceil(key.implicitWidth) + 2 * Tokens.px(7.68, hints.s)
                height: Math.ceil(key.implicitHeight) + 2 * Tokens.px(0.96, hints.s)
                color: Tokens.color.darkGray

                Label {
                    id: key
                    anchors.centerIn: parent
                    s: hints.s
                    size: 15.36
                    color: Tokens.color.lightYellow
                    text: String(hint.modelData.key)
                }
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                s: hints.s
                size: hints.textSize
                spacing: 1.536
                weight: Font.Normal
                color: Tokens.color.mediumGray
                text: String(hint.modelData.label)
            }
        }
    }
}
