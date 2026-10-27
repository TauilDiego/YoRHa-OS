pragma ComponentBehavior: Bound

import QtQuick
import "../popup"
import "../strings"

// The settings pop-up (spec 003): the PopupWindow titled "SYSTEM -Settings", with the version
// on the footer's left. shell.qml picks the screen and unloads it after closing.
PopupWindow {
    id: root

    signal closeRequested()

    title: Strings.settings.title
    subtitle: Strings.settings.subtitle
    footerLeft: Strings.settings.version
    onDismissed: closeRequested()

    // Provisional body (US1): Esc closes. Replaced by SettingsPage (US2).
    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()
    }
}
