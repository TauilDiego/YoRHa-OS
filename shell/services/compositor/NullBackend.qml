pragma ComponentBehavior: Bound

import QtQuick

// The compositor adapter's backend when no known compositor is running (contracts/compositor.md
// §1): empty lists, no title, and every action refused by its capabilities. The bar and the pause
// menu still open (on the first screen), with nothing to show.
Item {
    id: root

    readonly property string name: "none"
    readonly property var capabilities: ({
        workspaceModel: "numbered",
        canFloat: false,
        canMoveToWorkspace: false,
        actsOnAnyWindow: false,
        hasGeometry: "none",
        fullscreenKnown: false,
        keyboardLayouts: false
    })
    readonly property var monitors: []
    readonly property var workspaces: []
    readonly property var windows: []
    readonly property string activeTitle: ""
    readonly property bool fullscreen: false

    // spec 013 (front C): no keyboard layouts to read or set
    readonly property var keyboardLayouts: []
    signal changed()
    function setKeyboardLayouts(list: var): string {
        return "error: no compositor";
    }
    function refreshKeyboardLayouts(): void {
    }

    function activeIndexOn(monitorName: string): int {
        return 0;
    }
    function refresh(what: string): void {
    }
    function focusWorkspace(key: string): void {
    }
    function focusWindow(id: string): void {
    }
    function moveWindow(id: string, key: string): void {
    }
    function toggleFloating(id: string): void {
    }
    function closeWindow(id: string): void {
    }
    function validId(id: string): bool {
        return false;
    }
}
