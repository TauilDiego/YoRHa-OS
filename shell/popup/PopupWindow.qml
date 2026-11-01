pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../services"

// A pop-up over the desktop (spec 003, research R1/R2/R11): one transparent window over the
// whole monitor, on the Overlay layer, with the PopupFrame (the dimmed desktop and the paper
// panel). Reused by the wallpaper picker (spec 004).
// While `keyboardActive`, it takes the keyboard exclusively. Opening fades in over
// Tokens.motion.popupFade (instant when frozen or with reduced motion); closing is instant:
// with `keyboardActive: false` it hides, gives up the keyboard and lets clicks through, and the
// owner unloads it a moment later (closing in two steps keeps Qt's text-input plugin quiet).
// A click on the dimmed area emits dismissed(). Children go to the panel (see PopupFrame).
// spec 013: `presentation` (Appearance › Menu presentation by default) is the frame's: "floating"
// or "fullscreen" (PopupFrame).
// spec 013, front A (FR-009): the 007 fade is gone. Opening runs the frame's game opening (grid,
// triangles, assembly); closing (`keyboardActive: false`) gives the keyboard and the clicks up at
// once but keeps the frame shown while it closes (`closing`, Tokens.motion.popupClose at most),
// with the leaving row first when `leaveNext` (an action that leaves the menu, FR-008). The owner
// waits that long before unloading it. `anim` is the frame's.
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
    // spec 013
    property string presentation: Settings.menuPresentation
    property bool leaveNext: false               // front A: the next close is an action leaving
    readonly property bool closing: frame.closing

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
    WlrLayershell.namespace: "yorha-popup"
    WlrLayershell.keyboardFocus: keyboardActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    mask: keyboardActive ? null : noInput

    Region {
        id: noInput
    }

    PopupFrame {
        id: frame
        anchors.fill: parent
        visible: root.keyboardActive || root.closing
        motion: true
        title: root.title
        subtitle: root.subtitle
        footerLeft: root.footerLeft
        keys: root.keys
        tabs: root.tabs
        tab: root.currentTab
        clock: root.clock
        presentation: root.presentation
        onDismissed: root.dismissed()
        onTabClicked: index => root.tabClicked(index)
    }

    function appear(): void {
        Sounds.play("open");                  // spec 013, front D
        leaveNext = false;
        frame.open();
    }
    Component.onCompleted: appear()
    onKeyboardActiveChanged: {
        if (keyboardActive)
            appear();
        else {
            Sounds.play("close");             // spec 013, front D
            frame.close(leaveNext);
            leaveNext = false;
        }
    }
}
