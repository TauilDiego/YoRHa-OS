pragma ComponentBehavior: Bound

import QtQuick
import "../services"

// One wallpaper, filling its parent (spec 004, contracts/components.md): a scene, or (US4) a
// picture. `ready` turns true once there is something to show, so a transition never starts
// toward an empty picture.
// spec 004 US6: with `measureLuma` (the desktop's slots, which fill the monitor), a picture's top
// band is measured once it is on screen, for the bar's tone (WallpaperCatalog.lumas).
Item {
    id: root

    property var wallpaper: null                 // a WallpaperCatalog item
    property real s: 1
    property real phase: 0
    property size screenSize: Qt.size(width, height)   // physical px (pictures load at this size)
    property bool paperFilter: true
    property bool measureLuma: false

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
            readonly property bool loaded: picture.status === Image.Ready     // spec 004 US6

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

    // --- spec 004 US6: the mean luma of a picture's top band, as shown ---------------------------
    // The band is the bar plus 12 px (80 of 1080 at the default 68 px bar, the mockup's 40/540).
    // The picture item (paper filter included) is grabbed at 480 px wide and an invisible Canvas
    // reads the band's pixels (getImageData reads here; putImageData would paint nothing).
    readonly property string lumaPath: measureLuma && wallpaper?.type === "image" ? wallpaper.path : ""
    readonly property real luma: lumaPath ? WallpaperCatalog.lumaOf(lumaPath, paperFilter) : -1
    readonly property bool needsLuma: lumaPath !== "" && (view?.loaded ?? false) && luma < 0
    onNeedsLumaChanged: if (needsLuma) measureSoon.restart()
    Timer {
        id: measureSoon
        interval: 100                            // a frame or two, so the filter has drawn
        onTriggered: root.measure()
    }

    function measure(): void {
        const item = loader.item;
        if (!needsLuma || !item || width <= 0 || height <= 0)
            return;
        const w = probe.width;
        const h = Math.max(1, Math.round(w * height / width));
        const band = Math.max(1, Math.min(probe.height, Math.round(h * Math.min(1, (Settings.barHeight + 12) / height))));
        const path = lumaPath, filtered = paperFilter;
        if (!item.grabToImage(result => probe.take(result, path, filtered, band), Qt.size(w, h)))
            measureSoon.restart();
    }

    Canvas {
        id: probe
        width: 480
        height: 64
        opacity: 0                               // never shown; only read
        property var result: null                // kept alive: its url is only valid meanwhile
        property string path
        property bool filtered
        property int band: 1

        function take(r: var, p: string, f: bool, b: int): void {
            result = r;
            path = p;
            filtered = f;
            band = b;
            loadImage(r.url);
            if (isImageLoaded(r.url))            // already decoded: no imageLoaded signal
                requestPaint();
        }
        onImageLoaded: requestPaint()
        onPaint: {
            if (!result || !isImageLoaded(result.url))
                return;
            const c = getContext("2d");
            c.clearRect(0, 0, width, height);
            c.drawImage(result.url, 0, 0);
            const d = c.getImageData(0, 0, width, band).data;
            let sum = 0;
            for (let i = 0; i < d.length; i += 4)
                sum += 0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2];
            unloadImage(result.url);
            result = null;
            WallpaperCatalog.setLuma(path, filtered, Math.round(sum / (d.length / 4) / 255 * 1000) / 1000);
        }
    }
    // --- end spec 004 US6 --------------------------------------------------------------------------

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
