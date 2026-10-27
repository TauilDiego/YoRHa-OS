pragma ComponentBehavior: Bound

import QtQuick

// One wallpaper, filling its parent (spec 004, contracts/components.md): a scene, or (US4) a
// picture. `ready` turns true once there is something to show, so a transition never starts
// toward an empty picture.
Item {
    id: root

    property var wallpaper: null                 // a WallpaperCatalog item
    property real s: 1
    property real phase: 0
    property size screenSize: Qt.size(width, height)   // physical px (pictures load at this size)
    property bool paperFilter: true

    // loader.item is typed Item: go through a var, so qmllint accepts `ready`.
    readonly property var view: loader.item
    readonly property bool ready: view?.ready ?? false

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.wallpaper?.type === "scene" ? sceneView : null
    }

    Component {
        id: sceneView
        Scene {
            readonly property bool ready: true
            params: root.wallpaper.scene
            s: root.s
            phase: root.phase
        }
    }
}
