// rien-OS shell: YoRHa design system + HUD (spec 001).
import QtQuick
import Quickshell
import Quickshell.Io
import "ds"
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
