import QtQuick
import "../ds"

// The passage band (spec 011 FR-017, FR-013; mockup v3.2 ".bridge"; the 4K analysis of the game's
// boot): a flat dark band across the middle with one line of text. It opens and closes like a CRT
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
        color: "#0F0F0F"

        Label {
            anchors.centerIn: parent
            s: root.s
            size: 20.16
            spacing: 1.92
            weight: Font.Bold
            color: "#96958F"
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
