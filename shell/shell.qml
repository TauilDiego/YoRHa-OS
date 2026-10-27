// rien-OS shell: YoRHa design system + HUD (spec 001).
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "ds"
import "gallery"
import "hud"
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

    // One HUD per monitor (FR-009).
    Variants {
        id: huds
        model: Quickshell.screens

        Hud {}
    }

    // The design system gallery (US3): created only while open. A single instance; the
    // compositor puts it on the focused output. Closing happens in two steps: the gallery
    // first gives up its exclusive keyboard focus, and is unloaded a moment later, so Qt's
    // text-input plugin doesn't warn about a focused surface going away.
    property bool galleryLoaded: false
    onGalleryOpenChanged: {
        if (galleryOpen)
            galleryLoaded = true;
        else
            galleryUnload.restart();
    }
    Timer {
        id: galleryUnload
        interval: 150
        onTriggered: if (!shell.galleryOpen) shell.galleryLoaded = false
    }
    LazyLoader {
        active: shell.galleryLoaded
        Gallery {
            keyboardActive: shell.galleryOpen
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
        function dump(): string {
            const out = [];
            for (const hud of huds.instances)
                out.push(hud.dumpEntry());
            return JSON.stringify(out);
        }
    }
}
