pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../strings"

// The pause menu's POWER, session and power (frente C): contract skeleton (spec 007 T016).
FocusScope {
    id: root

    property real s: 1
    property real startY: Tokens.space.pauseBodyY
    property bool active: false              // the tab is open and the menu has the keyboard

    signal closeRequested()

    readonly property var keys: [{ key: Strings.settings.keyEsc, label: Strings.settings.close }]
    readonly property string footerLeft: ""

    function restart(): void {
    }
    function enter(): void {
    }
    function leave(): void {
    }
    function geometry(): var {
        return { item: null, value: null };
    }
    function dumpState(): var {
        return {};
    }

    Keys.onEscapePressed: closeRequested()

    Label {
        x: Tokens.px(48, root.s)
        y: Tokens.px(root.startY, root.s)
        s: root.s
        text: "POWER"
    }
}
