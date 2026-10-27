// rien-OS shell: YoRHa design system + HUD (spec 001).
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "ds"
import "gallery"
import "services"

ShellRoot {
    id: shell

    // Fixtures freeze animations so two screenshots are pixel-identical (SC-002).
    Binding {
        target: Tokens
        property: "frozen"
        value: Fixtures.active
    }

    property bool galleryOpen: false

    // The design system gallery (US3): created only while open. A single instance; the
    // compositor puts it on the focused output.
    LazyLoader {
        active: shell.galleryOpen
        Gallery {
            onCloseRequested: shell.galleryOpen = false
        }
    }

    // --- IPC (contracts/ipc.md) ---------------------------------------------------------------
    IpcHandler {
        target: "gallery"
        function open(): void { shell.galleryOpen = true; }
        function close(): void { shell.galleryOpen = false; }
        function toggle(): void { shell.galleryOpen = !shell.galleryOpen; }
        function isOpen(): string { return shell.galleryOpen ? "true" : "false"; }
    }

    IpcHandler {
        target: "fixtures"
        function load(path: string): string { return Fixtures.load(path); }
        function clear(): void { Fixtures.clear(); }
    }

    IpcHandler {
        target: "hud"
        function dump(): string { return JSON.stringify([]); }
    }
}
