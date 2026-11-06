import QtQuick
import ".."
import "../primitives"

// The on-screen display (spec 008, FR-028): a band of 672 × 72 (600 before U13) with the light block, a square, the
// label (VOLUME, BRIGHTNESS, MIC ON / MIC OFF), the inverted hp-bar of 300 (at 35% when muted, full
// above 100) and the number in its own column on the right (16 px after the meter), in tabular
// figures. MIC has no meter.
Item {
    id: root

    property real s: 1
    property real dpr: 1
    property string label
    property int value: 0
    property bool muted: false
    property bool meter: true
    property string valueText: String(value)

    readonly property var nt: Tokens.notify
    function u(v: real): int {
        return Tokens.px(v, s);
    }

    implicitWidth: u(nt.osdW)
    implicitHeight: u(nt.osdH)

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
            width: root.u(root.nt.osdLabelW)
            s: root.s
            role: "osdLabel"
            text: root.label
            color: Tokens.notify.bandText
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.meter
            width: root.u(root.nt.osdMeterW)
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
    // The number's own column (spec 010 item E), right-aligned in it: never over the meter. It is
    // at least osdNumW wide, wider if "MUTE" needs it at this size.
    TextMetrics {
        id: widest
        font: valueLabel.font
        text: "MUTE"
    }
    Label {
        id: valueLabel
        x: root.width - root.u(root.nt.osdRight) - width
        width: Math.max(root.u(root.nt.osdNumW), Math.ceil(widest.advanceWidth))
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        role: "osdValue"
        font.features: ({ "tnum": 1 })
        horizontalAlignment: Text.AlignRight
        text: root.valueText
        color: Tokens.notify.bandText
    }
}
