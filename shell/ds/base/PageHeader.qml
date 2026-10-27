import QtQuick
import ".."
import "../primitives"

// Page title (FR-006): the title in upper case with a hard text shadow down-right, offset by
// Tokens.shadow.textRatio of the text size, then the subtitle on the same baseline, prefixed
// with "-" like the game ("ITEMS -All Items").
Item {
    id: root

    property real s: 1
    property string title
    property string subtitle

    readonly property int shadowOffset: Math.round(heading.size * Tokens.shadow.textRatio)

    implicitWidth: sub.visible ? sub.x + sub.implicitWidth : heading.implicitWidth + shadowOffset
    implicitHeight: heading.implicitHeight + shadowOffset

    Label {
        x: root.shadowOffset
        y: root.shadowOffset
        s: root.s
        role: "pageHeader"
        upper: true
        text: root.title
        color: Tokens.color.textShadow
    }

    Label {
        id: heading
        s: root.s
        role: "pageHeader"
        upper: true
        text: root.title
    }

    Label {
        id: sub
        x: heading.implicitWidth + root.shadowOffset + Tokens.px(10, root.s)
        anchors.baseline: heading.baseline
        visible: root.subtitle !== ""
        s: root.s
        role: "subheader"
        text: root.subtitle.startsWith("-") ? root.subtitle : "-" + root.subtitle
    }
}
