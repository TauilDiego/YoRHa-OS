pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../strings"

// What can be put on the desktop (spec 004, contracts/services.md): the factory scenes
// (wallpaper/scenes/<id>.json, in factory order), the pictures in the wallpaper folder (by name)
// and the video entry, dimmed until U6. The folder is watched and only read, never created or
// changed; no file name ever goes through a shell (FR-011, FR-012). A file that is not a picture
// stays out, with a line in the log.
Singleton {
    id: root

    readonly property var sceneIds: ["menu", "rules", "dark", "plain"]
    property var scenes: []

    // The folder in use: the fixture's (relative to the shell) or the user's setting.
    readonly property string folder: {
        const f = Fixtures.get("wallpaper")?.folder;
        return typeof f === "string" && f !== "" ? Fixtures.resolve(f) : Settings.wallpaperFolder;
    }
    readonly property bool folderMissing: folder === "" || (parentModel.status === FolderListModel.Ready && !folderFound)
    property bool folderFound: false

    readonly property var video: ({
        id: "video:later",
        type: "video",
        name: Strings.wallpaper.videoName,
        description: Strings.wallpaper.videoText,
        group: Strings.wallpaper.video,
        available: false
    })

    // Pictures that decoded, in the folder's order (by name).
    property var probes: ({})           // path → true (decodes) / false (broken)
    property int listRevision: 0
    readonly property var images: {
        void listRevision;
        const out = [];
        if (folderMissing)
            return out;
        for (let i = 0; i < folderModel.count; i++) {
            const path = String(folderModel.get(i, "filePath"));
            if (probes[path] !== true)
                continue;
            out.push({
                id: "image:" + path,
                type: "image",
                name: String(folderModel.get(i, "fileName")),
                description: Strings.wallpaper.imageText,
                group: Strings.wallpaper.images,
                url: folderModel.get(i, "fileUrl"),
                path: path,
                available: true
            });
        }
        return out;
    }
    // Every file listed has been sniffed (until then a saved picture waits: see WallpaperStore).
    readonly property bool ready: {
        void listRevision;
        if (folderMissing)
            return true;
        if (folderModel.status !== FolderListModel.Ready)
            return false;
        for (let i = 0; i < folderModel.count; i++)
            if (probes[String(folderModel.get(i, "filePath"))] === undefined)
                return false;
        return true;
    }

    readonly property var items: scenes.concat(images, [video])
    readonly property int count: items.length

    function byId(id: string): var {
        return items.find(w => w.id === id) ?? null;
    }

    // A local path as a file URL, each segment encoded (spaces, quotes, #, %…).
    function fileUrl(path: string): string {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    // Re-read the folder (e.g. when the picker opens and the folder has just been created).
    function refresh(): void {
        folderModel.folder = "";
        folderModel.folder = Qt.binding(() => root.folder ? root.fileUrl(root.folder) : "");
        listRevision++;
    }

    // --- scenes: read once, synchronously, at start ----------------------------------------------
    FileView {
        id: sceneReader
        blockLoading: true
        printErrors: false
    }

    function loadScenes(): void {
        const out = [];
        for (const sid of sceneIds) {
            sceneReader.path = Quickshell.shellPath(`wallpaper/scenes/${sid}.json`);
            sceneReader.reload();
            sceneReader.waitForJob();
            let params = null;
            try {
                params = JSON.parse(sceneReader.text());
            } catch (e) {
                console.warn(`wallpaper: scene ${sid}.json is not valid JSON (${e}), skipping it`);
                continue;
            }
            out.push({
                id: "scene:" + sid,
                type: "scene",
                name: String(params.name ?? sid),
                description: String(params.description ?? ""),
                group: Strings.wallpaper.scenes,
                url: Qt.resolvedUrl(`../wallpaper/scenes/${sid}.json`),
                scene: params,
                available: true
            });
        }
        scenes = out;
    }

    Component.onCompleted: loadScenes()

    // --- pictures: the folder, watched by Qt --------------------------------------------------------
    FolderListModel {
        id: folderModel
        folder: root.folder ? root.fileUrl(root.folder) : ""
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        caseSensitive: false
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onCountChanged: root.listRevision++
        onStatusChanged: root.listRevision++
    }

    // Which files are pictures: one `file` run over the new names (a header sniff; the names go
    // as arguments, never through a shell). Qt's Image would log a warning for every file it
    // can't decode (SC-008: no QML warnings), so a broken file is caught here, before any Image
    // sees it, and only gets a line in the log.
    readonly property var pictureTypes: ["image/jpeg", "image/png", "image/webp"]
    Process {
        id: sniffer
        property var paths: []
        command: ["file", "--brief", "--mime-type", "--"].concat(paths)
        stdout: StdioCollector {
            onStreamFinished: root.sniffed(sniffer.paths, text.split("\n"))
        }
    }
    Timer {
        id: sniffSoon
        interval: 50
        onTriggered: root.sniffNext()
    }
    onListRevisionChanged: sniffSoon.restart()

    function sniffNext(): void {
        if (sniffer.running)
            return;
        const todo = [];
        for (let i = 0; i < folderModel.count; i++) {
            const path = String(folderModel.get(i, "filePath"));
            if (probes[path] === undefined)
                todo.push(path);
        }
        if (todo.length === 0)
            return;
        sniffer.paths = todo;
        sniffer.running = true;
    }

    function sniffed(paths: var, lines: var): void {
        const p = Object.assign({}, probes);
        for (let i = 0; i < paths.length; i++) {
            const ok = pictureTypes.includes(String(lines[i] ?? "").trim());
            p[paths[i]] = ok;
            if (!ok)
                console.info(`wallpaper: skipping ${paths[i]}: not a jpg, png or webp picture`);
        }
        probes = p;
        sniffSoon.restart();               // files that arrived meanwhile
    }

    // --- spec 004 US6: the bar's tone over pictures ------------------------------------------------
    // The mean luma of each picture's top band as shown (WallpaperView measures it once, when the
    // picture is ready), by path and by paper filter on/off. Dropped when the file leaves the folder.
    property var lumas: ({})
    function lumaKey(path: string, filtered: bool): string {
        return (filtered ? "1:" : "0:") + path;
    }
    function lumaOf(path: string, filtered: bool): real {
        return lumas[lumaKey(path, filtered)] ?? -1;
    }
    function setLuma(path: string, filtered: bool, value: real): void {
        const l = Object.assign({}, lumas);
        l[lumaKey(path, filtered)] = value;
        lumas = l;
    }
    onImagesChanged: {
        const here = new Set(images.map(w => w.path));
        const keep = {};
        let dropped = false;
        for (const k in lumas) {
            if (here.has(k.slice(2)))
                keep[k] = lumas[k];
            else
                dropped = true;
        }
        if (dropped)
            lumas = keep;
    }
    // --- end spec 004 US6 --------------------------------------------------------------------------

    // Does the folder exist? Its parent is listed (directories only) and watched, so a folder
    // created later is picked up too.
    readonly property string parentDir: folder.replace(/\/+$/, "").replace(/\/[^/]*$/, "") || "/"
    FolderListModel {
        id: parentModel
        folder: root.folder ? root.fileUrl(root.parentDir) : ""
        showFiles: false
        showDirs: true
        showDotAndDotDot: false
        showHidden: true
        onCountChanged: root.checkFolder()
        onStatusChanged: root.checkFolder()
    }
    property bool folderChecked: false
    onFolderChanged: folderChecked = false

    function checkFolder(): void {
        if (parentModel.status !== FolderListModel.Ready)
            return;
        const name = folder.replace(/\/+$/, "").replace(/^.*\//, "");
        let found = false;
        for (let i = 0; i < parentModel.count && !found; i++)
            found = String(parentModel.get(i, "fileName")) === name;
        // Created while the shell runs: the folder model gave up on it, so list it again.
        if (found && !folderFound && folderChecked)
            Qt.callLater(refresh);
        folderFound = found;
        folderChecked = true;
    }
}
