import QtQuick
import ".."
import "../primitives"

// Headered card: ink header band with the title, lightYellow body (the default property) and
// an optional right-aligned footer, with the hard box shadow. 538×578 by default.
// spec 004: `mark` puts the light 14 px square before the title (the picker's cards, as in the
// DescriptionCard of spec 003); a title that doesn't fit scrolls (spec 013, FR-012; cut with an
// ellipsis with Tokens.instant).
// spec 013 (front A): `paper` (0–1) fades the shadow, the body and the footer, never the header
// band (the game's dialog shows its title band first, FR-010).
Item {
    id: root

    property real s: 1
    property string title
    property string footer: ""
    property bool mark: false
    property real paper: 1                       // spec 013
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
        opacity: root.paper
        color: Tokens.color.boxShadow
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.paper
        color: Tokens.color.lightYellow
    }

    Rectangle {
        width: root.width
        height: root.headerH
        color: Tokens.color.darkGray

        Square {
            id: headerMark
            x: root.margin
            anchors.verticalCenter: parent.verticalCenter
            visible: root.mark
            s: root.s
            size: 14
            color: Tokens.color.lightYellow
        }
        // spec 013 (FR-012): a title that doesn't fit scrolls.
        ScrollingLabel {
            x: root.mark ? headerMark.x + headerMark.width + Tokens.px(14, root.s) : root.margin
            width: Math.max(0, Math.min(Math.ceil(implicitWidth), root.width - x - root.margin))
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
        opacity: root.paper
    }

    Label {
        id: foot
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.margin
        visible: root.footer !== ""
        opacity: root.paper
        s: root.s
        role: "cardHeader"
        text: root.footer
    }
}
