pragma ComponentBehavior: Bound

import QtQuick
import "../popup"
import "../strings"

// The settings pop-up (spec 003): the PopupWindow titled "SYSTEM -Settings", with the version
// on the footer's left, the key hints of the focus on its right and SettingsPage as the body.
// shell.qml picks the screen, keeps `category` between openings and unloads it after closing.
PopupWindow {
    id: root

    property alias category: page.category

    signal closeRequested()

    function dumpState(): var {
        return page.dumpState();
    }

    function restart(index: int): void {
        page.restart(index);
    }

    title: Strings.settings.title
    subtitle: Strings.settings.subtitle
    footerLeft: Strings.settings.version
    keys: page.keys
    onDismissed: closeRequested()
    // Reopened before it was unloaded: back to the categories, as a fresh one starts.
    onKeyboardActiveChanged: if (keyboardActive) page.restart(page.category)

    SettingsPage {
        id: page
        anchors.fill: parent
        s: root.s
        focus: true
        onCloseRequested: root.closeRequested()
    }
}
