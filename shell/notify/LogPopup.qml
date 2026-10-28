pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../popup"

// The text log's pop-up (spec 008, FR-020): the 003 PopupWindow ("LOG -Transmissions", the dimmed
// desktop, the keyboard only for it, Esc or a click outside closes it) with the LogPage as its body.
// shell.qml picks the screen (the focused one), sets NotifyStore.logOpen and unloads it after closing.
PopupWindow {
    id: root

    signal closeRequested()

    function dumpState(): var {
        return page.dumpState();
    }
    function restart(): void {
        page.restart();
    }

    title: page.title
    subtitle: page.subtitle
    footerLeft: page.footerLeft
    keys: page.keys
    onDismissed: closeRequested()
    onKeyboardActiveChanged: if (keyboardActive) page.restart()

    LogPage {
        id: page
        anchors.fill: parent
        s: root.s
        dpr: Tokens.scaleOf(root.screen?.name ?? "")
        host: "popup"
        monitor: root.screen?.name ?? ""
        focus: true
        onCloseRequested: root.closeRequested()
    }
}
