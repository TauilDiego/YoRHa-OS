import QtQuick
import "."

// The loading ring (spec 011 FR-010, the "one loading animation" rule of spec 010 item D): the
// cursor theme's Loading_Circle frames (NieR Cursors by Beinsezii, MIT, recolored ink on paper,
// assets/ring/frames.txt), 90 frames at 60 frames/s. It only runs while `running`; reduced motion
// keeps it turning, since a still ring would read as a hang.
Item {
    id: root

    property bool running: false
    property int frame: 0

    readonly property int frames: 90
    readonly property int frameMs: 17

    implicitWidth: 64
    implicitHeight: 64

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/ring/ring-" + (root.frame < 10 ? "0" : "") + root.frame + ".png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    NumberAnimation {
        target: root
        property: "frame"
        from: 0
        to: root.frames - 1
        duration: root.frames * root.frameMs
        loops: Animation.Infinite
        running: root.running && root.visible
    }
}
