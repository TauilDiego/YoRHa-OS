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
        sourceComponent: root.wallpaper?.type === "scene" ? sceneView
            : root.wallpaper?.type === "image" ? imageView : null
    }

    // A picture covers the screen without stretching (the excess is cut), decoded at the screen's
    // physical size off the UI thread, and gets the paper filter unless it was turned off.
    Component {
        id: imageView
        Item {
            readonly property bool ready: picture.status === Image.Ready || picture.status === Image.Error

            Image {
                id: picture
                anchors.fill: parent
                source: root.wallpaper.url
                fillMode: Image.PreserveAspectCrop
                sourceSize: root.screenSize
                asynchronous: true
                cache: false
            }
            PaperFilter {
                anchors.fill: parent
                enabled: root.paperFilter
                source: picture
                textureSize: root.screenSize
            }
        }
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
