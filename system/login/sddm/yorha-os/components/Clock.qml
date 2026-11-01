import QtQuick
import "../ds"

// The center column (spec 011; mockup v3.2 ".center"): the big clock, the date and the system's
// name. The theme's `clock` option: big (the mockup), small (provisional size, pending the owner's
// choice) or none (no clock nor date; the name stays).
Column {
    id: root

    property real s: 1
    property string mode: "big"

    property date now: new Date()
    function pad(n: int): string {
        return (n < 10 ? "0" : "") + n;
    }

    spacing: Tokens.px(10.56, s)

    Timer {
        interval: 1000
        repeat: true
        running: root.mode !== "none"
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Label {
        visible: root.mode !== "none"
        anchors.horizontalCenter: parent.horizontalCenter
        s: root.s
        size: root.mode === "small" ? 61.44 : 122.88
        spacing: root.mode === "small" ? 2.88 : 5.76
        height: pixelSize
        verticalAlignment: Text.AlignVCenter
        font.features: ({ "tnum": 1 })
        text: root.pad(root.now.getHours()) + ":" + root.pad(root.now.getMinutes())
    }
    Label {
        visible: root.mode !== "none"
        anchors.horizontalCenter: parent.horizontalCenter
        s: root.s
        size: 21.12
        spacing: 6.72
        weight: Font.Normal
        color: Tokens.color.mediumGray
        height: Tokens.px(21.12 * 1.55, root.s)
        verticalAlignment: Text.AlignVCenter
        text: root.now.getFullYear() + "." + root.pad(root.now.getMonth() + 1) + "." + root.pad(root.now.getDate())
    }
    Item {
        visible: root.mode !== "none"
        width: 1
        height: Tokens.px(42.24, root.s) - root.spacing
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.px(5.76, root.s)
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            s: root.s
            size: 30.72
            spacing: 9.6
            weight: Font.Bold
            height: Tokens.px(30.72 * 1.55, root.s)
            verticalAlignment: Text.AlignVCenter
            text: "YoRHa-OS"
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            s: root.s
            size: 15.36
            spacing: 7.68
            color: Tokens.color.mediumGray
            height: Tokens.px(15.36 * 1.55, root.s)
            verticalAlignment: Text.AlignVCenter
            text: "SYSTEM INTERFACE"
        }
    }
}
