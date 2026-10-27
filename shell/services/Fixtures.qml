pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Test data (FR-015). A JSON file named by $NIER_FIXTURES, or loaded over IPC, replaces the
// real source of each domain it contains; a missing domain keeps real data
// (contracts/fixtures.schema.json). Relative paths resolve against the shell directory.
Singleton {
    id: root

    property string source: resolve(Quickshell.env("NIER_FIXTURES") ?? "")
    readonly property bool active: source !== "" && data !== null
    readonly property var data: file.loaded ? parse(file.text()) : null

    // Does the active fixture define this domain? (e.g. has("battery"), even when it is null)
    function has(domain: string): bool {
        // `data` checked again: while the shell tears down, `active` can still read true for a
        // moment after the file is gone (a TypeError in the log otherwise).
        return active && data !== null && Object.prototype.hasOwnProperty.call(data, domain);
    }

    function get(domain: string): var {
        return has(domain) ? data[domain] : undefined;
    }

    // IPC: switch scenario without restarting. Returns "ok" or the error.
    function load(path: string): string {
        const p = resolve(path);
        const check = parse(readNow(p));
        if (check === null)
            return `error: cannot read fixture ${p}`;
        source = p;
        return "ok";
    }

    function clear(): void {
        source = "";
    }

    function resolve(path: string): string {
        if (!path)
            return "";
        if (path.startsWith("~/"))
            return Quickshell.env("HOME") + path.slice(1);
        return path.startsWith("/") ? path : Quickshell.shellPath(path);
    }

    function parse(text: string): var {
        if (!text)
            return null;
        try {
            const d = JSON.parse(text);
            return (d && typeof d === "object" && !Array.isArray(d)) ? d : null;
        } catch (e) {
            return null;
        }
    }

    function readNow(path: string): string {
        probe.path = path;
        probe.reload();
        probe.waitForJob();
        return probe.loaded ? probe.text() : "";
    }

    FileView {
        id: file
        path: root.source
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: probe
        printErrors: false
        blockLoading: true
    }
}
