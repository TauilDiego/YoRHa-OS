pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"

// A pop-up over the desktop (spec 003, research R1/R2/R11): one transparent window over the
// whole monitor, on the Overlay layer, with the PopupFrame (the dimmed desktop and the paper
// panel). Reused by the wallpaper picker (spec 004).
// While `keyboardActive`, it takes the keyboard exclusively. Opening fades in over
// Tokens.motion.popupFade (instant when frozen or with reduced motion); closing is instant:
// with `keyboardActive: false` it hides, gives up the keyboard and lets clicks through, and the
// owner unloads it a moment later (closing in two steps keeps Qt's text-input plugin quiet).
// A click on the dimmed area emits dismissed(). Children go to the panel (see PopupFrame).
PanelWindow {
    id: root

    property bool keyboardActive: true
    property string title
    property string subtitle
    property string footerLeft
    property var keys: []
    default property alias content: frame.content
    readonly property real s: frame.s
    readonly property Item panel: frame.panel
    // spec 007: the frame with tabs (the pause menu)
    property var tabs: []
    property int currentTab: 0
    property bool clock: false
    readonly property int bodyTop: frame.bodyTop
    readonly property PopupFrame popupFrame: frame

    signal dismissed()
    signal tabClicked(int index)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rien-popup"
    WlrLayershell.keyboardFocus: keyboardActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    mask: keyboardActive ? null : noInput

    Region {
        id: noInput
    }

    PopupFrame {
        id: frame
        anchors.fill: parent
        visible: root.keyboardActive
        opacity: 0
        title: root.title
        subtitle: root.subtitle
        footerLeft: root.footerLeft
        keys: root.keys
        tabs: root.tabs
        tab: root.currentTab
        clock: root.clock
        onDismissed: root.dismissed()
        onTabClicked: index => root.tabClicked(index)
    }

    NumberAnimation {
        id: fade
        target: frame
        property: "opacity"
        from: 0
        to: 1
        duration: Tokens.motion.popupFade
        easing.type: Easing.OutCubic
    }

    function appear(): void {
        fade.stop();
        if (Tokens.instant)
            frame.opacity = 1;
        else
            fade.start();
    }
    Component.onCompleted: appear()
    onKeyboardActiveChanged: if (keyboardActive) appear()
}
