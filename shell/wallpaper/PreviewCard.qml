pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../strings"

// The wallpaper picker's preview (spec 004, research R10): the headed Card with the wallpaper's
// name, the wallpaper itself drawn small and live in a 2 px medium-gray frame — a scene at the
// box's own scale (512/1920), a picture decoded at the box's physical size with the paper filter
// unless it is off, the video entry as "NOT YET" — and its description under it.
// The parent sets the width; the height follows the description (at least 100 game px of it).
Item {
    id: root

    property real s: 1
    property var wallpaper: null                 // a WallpaperCatalog item
    property real phase: 0
    property real dpr: 1                         // the monitor's real scale (pictures load at it)
    property bool paperFilter: true

    readonly property int pad: Tokens.px(24, s)
    readonly property int mediaW: Tokens.px(Tokens.space.pickerMediaW, s)
    readonly property int mediaH: Tokens.px(Tokens.space.pickerMediaH, s)
    readonly property int frame: Tokens.line(2, s)
    readonly property int textY: media.y + mediaH + Tokens.px(18, s)

    implicitWidth: Tokens.px(Tokens.space.pickerPreviewW, s)
    implicitHeight: textY + Math.max(Tokens.px(100, s), Math.ceil(description.implicitHeight)) + pad

    Card {
        id: card
        anchors.fill: parent
        s: root.s
        mark: true
        title: String(root.wallpaper?.name ?? "")
    }

    Rectangle {
        x: media.x - root.frame
        y: media.y - root.frame
        width: root.mediaW + 2 * root.frame
        height: root.mediaH + 2 * root.frame
        color: Tokens.color.mediumGray
    }

    Item {
        id: media
        x: Math.round((root.width - root.mediaW) / 2)
        y: card.headerH + root.pad
        width: root.mediaW
        height: root.mediaH
        clip: true

        // Under a picture still loading, and the video's box.
        Rectangle {
            anchors.fill: parent
            color: Tokens.color.lightGray
        }

        WallpaperView {
            anchors.fill: parent
            wallpaper: root.wallpaper
            s: height / 1080
            phase: root.phase
            screenSize: Qt.size(Math.round(width * root.dpr), Math.round(height * root.dpr))
            paperFilter: root.paperFilter
        }

        Label {
            anchors.centerIn: parent
            visible: root.wallpaper?.type === "video"
            s: root.s
            role: "standard"
            font.weight: Font.Medium
            font.variableAxes: ({ "wght": Font.Medium })
            text: Strings.wallpaper.notYet
            color: Tokens.color.mediumGray
        }
    }

    // As the mockup's preview text: 23 px, weight 500, lines 1.45 × the size apart.
    Label {
        id: description
        x: root.pad
        y: root.textY
        width: root.width - 2 * root.pad
        s: root.s
        role: "standard"
        font.weight: Font.Medium
        font.variableAxes: ({ "wght": Font.Medium })
        lineHeightMode: Text.FixedHeight
        lineHeight: Math.round(size * 1.45)
        wrapMode: Text.Wrap
        text: String(root.wallpaper?.description ?? "")
    }
}
