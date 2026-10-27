pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../services"

// The pop-up's look (spec 003, research R1/R5), without the window: ink over the whole area
// (Tokens.color.dim, never blurred) and, centered on it, a paper panel of
// Tokens.space.popupShare of the area, with a hard ink shadow, the page title, a plain rule under
// it, a plain rule over the footer, a text on the footer's left, the key hints on its right and
// the vignette on top. A click on the ink emits dismissed(); clicks on the panel stay there.
// The body (default property) fills the panel; it is laid out in px of a 1612×908 game-px frame
// times `s` = min(panel height / 908, panel width / 1612) × uiScale. On screens taller than 16:9
// the extra height goes above the footer, which stays at the panel's bottom.
// PopupWindow puts it in a window; the gallery shows it as a miniature.
Item {
    id: root

    property string title
    property string subtitle
    property string footerLeft
    property var keys: []
    default property alias content: body.data

    signal dismissed()

    readonly property real s: Math.min(panelH / Tokens.space.popupH, panelW / Tokens.space.popupW) * Settings.uiScale
    readonly property Item panel: panelItem

    // Edges on the monitor's physical pixels, as the other surfaces do.
    readonly property var window: QsWindow.window
    readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")
    readonly property real panelW: Tokens.snap(width * Tokens.space.popupShare, dpr)
    readonly property real panelH: Tokens.snap(height * Tokens.space.popupShare, dpr)

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    Rectangle {
        anchors.fill: parent
        color: Tokens.color.dim
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.dismissed()
    }

    Item {
        id: panelItem
        x: Tokens.snap((root.width - root.panelW) / 2, root.dpr)
        y: Tokens.snap((root.height - root.panelH) / 2, root.dpr)
        width: root.panelW
        height: root.panelH

        // Footer, measured from the panel's bottom (908 − 820 and 908 − 846 game px).
        readonly property int footerRuleY: height - root.u(Tokens.space.popupH - 820)
        readonly property int footerY: height - root.u(Tokens.space.popupH - 846)

        Rectangle {
            x: root.u(Tokens.shadow.popup)
            y: root.u(Tokens.shadow.popup)
            width: parent.width
            height: parent.height
            color: Tokens.color.darkGray
        }

        Rectangle {
            anchors.fill: parent
            color: Tokens.color.darkYellow
        }

        // Clicks on the paper never reach the ink behind it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        PageHeader {
            x: root.u(48)
            y: root.u(42)
            s: root.s
            title: root.title
            subtitle: root.subtitle
        }

        Rule {
            x: root.u(48)
            y: root.u(112)
            width: parent.width - 2 * x
            s: root.s
        }

        Rule {
            x: root.u(48)
            y: panelItem.footerRuleY
            width: parent.width - 2 * x
            s: root.s
        }

        KeyHints {
            id: hints
            anchors.right: parent.right
            anchors.rightMargin: root.u(48)
            y: panelItem.footerY
            s: root.s
            model: root.keys
        }

        Label {
            x: root.u(48)
            anchors.verticalCenter: hints.verticalCenter
            s: root.s
            role: "small"
            text: root.footerLeft
            color: Tokens.color.mediumGray
        }

        Item {
            id: body
            anchors.fill: parent
        }

        Vignette {
            anchors.fill: parent
            s: root.s
            enabled: Settings.vignette
        }
    }
}
