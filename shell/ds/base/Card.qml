import QtQuick
import ".."
import "../primitives"

// Headered card: ink header band with the title, lightYellow body (the default property) and
// an optional right-aligned footer, with the hard box shadow. 538×578 by default.
Item {
    id: root

    property real s: 1
    property string title
    property string footer: ""
    default property alias content: body.data

    readonly property int headerH: Tokens.px(49, s)      // measured on the Figma card (27 + 2×11)
    readonly property int margin: Tokens.px(Tokens.space.cardBodyMarginH, s)

    implicitWidth: Tokens.px(Tokens.space.cardW, s)
    implicitHeight: Tokens.px(Tokens.space.cardH, s)

    Rectangle {
        x: Tokens.px(Tokens.shadow.boxX, root.s)
        y: Tokens.px(Tokens.shadow.boxY, root.s)
        width: root.width
        height: root.height
        color: Tokens.color.boxShadow
    }

    Rectangle {
        anchors.fill: parent
        color: Tokens.color.lightYellow
    }

    Rectangle {
        width: root.width
        height: root.headerH
        color: Tokens.color.darkGray

        Label {
            x: root.margin
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            role: "cardHeader"
            text: root.title
            color: Tokens.color.lightYellow
        }
    }

    Item {
        id: body
        x: root.margin
        y: root.headerH + root.margin
        width: root.width - 2 * root.margin
        height: (foot.visible ? foot.y - Tokens.px(Tokens.space.cardBodyGap, root.s) : root.height - root.margin) - y
        clip: true
    }

    Label {
        id: foot
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.margin
        visible: root.footer !== ""
        s: root.s
        role: "cardHeader"
        text: root.footer
    }
}
