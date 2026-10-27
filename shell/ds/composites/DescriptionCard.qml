pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"

// Description card (spec 003): the headered Card saying what has the focus, as in the mockup:
// a square and the title in the ink band; the description; an optional note — "alert" (what to
// do first, in the alert color) or "info" (an action in progress, in ink); and label/value rows
// at the foot (DEFAULT/NOW, or SETTINGS).
//   meta: a JS array of { label, value }.
// The parent sets the width. The height follows the text between minHeight and maxHeight (px);
// a description that still doesn't fit is cut with an ellipsis.
Item {
    id: root

    property real s: 1
    property string title
    property string text
    property string note: ""
    property string noteKind: "alert"
    property var meta: []
    property real minHeight: Tokens.px(360, s)
    property real maxHeight: Tokens.px(Tokens.space.cardH, s)

    readonly property int margin: Tokens.px(Tokens.space.cardBodyMarginH, s)
    readonly property int gap: Tokens.px(22, s)                 // between text, note and rows
    readonly property int bottomMargin: Tokens.px(26, s)
    readonly property int textTop: card.headerH + margin
    readonly property int noteBlock: note !== "" ? Math.ceil(noteLabel.implicitHeight) + gap : 0
    readonly property int metaBlock: meta.length > 0 ? Math.ceil(metaGrid.implicitHeight) + gap : 0
    readonly property int natural: textTop + Math.ceil(measure.implicitHeight) + noteBlock + metaBlock + bottomMargin
    // Room left for the description once the card's height is settled.
    readonly property int textRoom: Math.max(measure.lineHeight, height - textTop - noteBlock - metaBlock - bottomMargin)

    implicitWidth: Tokens.px(Tokens.space.settingsCardW, s)
    implicitHeight: Math.max(minHeight, Math.min(maxHeight, natural))

    Card {
        id: card
        anchors.fill: parent
        s: root.s
        title: ""
    }

    // The title row over the card's ink band: a light square, then the title.
    Square {
        id: mark
        x: root.margin
        y: Math.round((card.headerH - height) / 2)
        s: root.s
        size: 14
        color: Tokens.color.lightYellow
    }
    Label {
        x: mark.x + mark.width + Tokens.px(14, root.s)
        width: root.width - x - root.margin
        anchors.verticalCenter: mark.verticalCenter
        s: root.s
        role: "cardHeader"
        elide: Text.ElideRight
        text: root.title
        color: Tokens.color.lightYellow
    }

    // The description, as the mockup's card text: 23 px, weight 500, lines 1.5 × the size apart
    // (CSS line-height; Qt's proportional mode would multiply the font's own, larger spacing).
    component Body: Label {
        width: root.width - 2 * root.margin
        s: root.s
        role: "standard"
        font.weight: Font.Medium
        font.variableAxes: ({ "wght": Font.Medium })
        lineHeightMode: Text.FixedHeight
        lineHeight: Math.round(size * 1.5)
        wrapMode: Text.Wrap
        text: root.text
    }
    Body {
        id: measure                                  // its natural height, never shown
        visible: false
    }
    Body {
        id: description
        x: root.margin
        y: root.textTop
        height: Math.min(Math.ceil(measure.implicitHeight), root.textRoom)
        elide: Text.ElideRight
    }

    Label {
        id: noteLabel
        x: root.margin
        y: description.y + description.height + root.gap
        width: root.width - 2 * root.margin
        visible: root.note !== ""
        s: root.s
        role: "small"
        font.weight: Font.DemiBold
        font.variableAxes: ({ "wght": Font.DemiBold })
        font.letterSpacing: root.s
        lineHeightMode: Text.FixedHeight
        lineHeight: Math.round(size * 1.4)
        wrapMode: Text.Wrap
        text: root.note
        color: root.noteKind === "info" ? Tokens.color.darkGray : Tokens.color.alert
    }

    // Label/value rows, pinned to the card's foot.
    Grid {
        id: metaGrid
        x: root.margin
        y: root.height - root.bottomMargin - height
        columns: 2
        rowSpacing: Tokens.px(10, root.s)
        columnSpacing: Tokens.px(20, root.s)

        Repeater {
            model: root.meta.reduce((cells, m) => cells.concat([
                { text: String(m?.label ?? ""), value: false },
                { text: String(m?.value ?? ""), value: true }
            ]), [])

            Label {
                required property var modelData
                s: root.s
                role: "small"
                font.weight: modelData.value ? Font.DemiBold : Font.Medium
                font.variableAxes: ({ "wght": modelData.value ? Font.DemiBold : Font.Medium })
                text: modelData.text
                color: modelData.value ? Tokens.color.darkGray : Tokens.color.mediumGray
            }
        }
    }
}
