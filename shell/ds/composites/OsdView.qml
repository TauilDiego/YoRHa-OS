import QtQuick
import ".."
import "../primitives"
import "../base"

// The on-screen display (spec 008, FR-028): a band of 600 × 72 with the light block, a square, the
// label (VOLUME, BRIGHTNESS, MIC ON / MIC OFF), the inverted hp-bar of 300 (at 35% when muted, full
// above 100) and the number on the right, in tabular figures. MIC has no meter.
Item {
    id: root

    property real s: 1
    property real dpr: 1
    property string label
    property int value: 0
    property bool muted: false
    property bool meter: true
    property string valueText: String(value)

    readonly property var N: Tokens.notify
    function u(v: real): int {
        return Tokens.px(v, s);
    }

    implicitWidth: u(N.osdW)
    implicitHeight: u(N.osdH)

    Band {
        anchors.fill: parent
        s: root.s
        dpr: root.dpr
        block: Tokens.color.lightYellow
    }

    Row {
        x: root.u(38)
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.u(18)

        Square {
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            size: 14
            color: Tokens.notify.bandText
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: root.u(root.N.osdLabelW)
            s: root.s
            role: "osdLabel"
            text: root.label
            color: Tokens.notify.bandText
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.meter
            width: root.u(root.N.osdMeterW)
            height: Tokens.px(Tokens.space.meterH, root.s)
            color: Tokens.notify.bandTrack
            opacity: root.muted ? 0.35 : 1
            Rectangle {
                width: Math.round(parent.width * Math.max(0, Math.min(100, root.value)) / 100)
                height: parent.height
                color: Tokens.color.lightYellow
            }
        }
    }
    Label {
        anchors.right: parent.right
        anchors.rightMargin: root.u(30)
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        role: "osdValue"
        font.features: ({ "tnum": 1 })
        horizontalAlignment: Text.AlignRight
        text: root.valueText
        color: Tokens.notify.bandText
    }
}
