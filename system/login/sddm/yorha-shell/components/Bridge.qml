import QtQuick
import "../ds"

// The passage band (spec 011 FR-017, FR-013; mockup v3.2 ".bridge"): a flat dark band across the
// middle with one line of text, in the numbers measured in the game (the 4K analysis, as the boot
// theme's band draws it, contracts/plymouth-theme.md): rgb(15,15,15), the text rgb(138,137,135) in the
// normal weight, without glow, so the two bands meet without a seam. It opens and closes like a CRT
// line: a dot in the center, a thin line for one frame, the band; and back: a thin line for one
// frame, then nothing. The parent drives `mode`: off | dot | line | band.
Item {
    id: root

    property real s: 1
    property string mode: "off"
    property string text: "Loading user data…"

    // band y 41.8–59.5 % of the screen; the closing line y 49.4 %, 1.5 % tall
    readonly property int lineY: Math.round(height * 0.494)
    readonly property int lineH: Math.max(1, Math.round(height * 0.015))

    Rectangle {
        visible: root.mode === "band"
        y: Math.round(root.height * 0.418)
        width: root.width
        height: Math.round(root.height * 0.177)
        color: Qt.rgba(15 / 255, 15 / 255, 15 / 255, 1)

        Label {
            anchors.centerIn: parent
            s: root.s
            size: 20.16
            spacing: 1.92
            weight: Font.Normal
            color: Qt.rgba(138 / 255, 137 / 255, 135 / 255, 1)
            text: root.text
        }
    }
    Rectangle {
        visible: root.mode === "line"
        y: root.lineY
        width: root.width
        height: root.lineH
        color: "#282828"
    }
    Rectangle {
        visible: root.mode === "dot"
        x: Math.round((root.width - width) / 2)
        y: root.lineY
        width: root.lineH
        height: root.lineH
        color: "#282828"
    }
}
