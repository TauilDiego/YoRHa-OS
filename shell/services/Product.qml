pragma Singleton

import QtQuick
import Quickshell

// The product's name and folders (spec 015, research R5), so that no service writes the name by hand.
// `yorha shell start` exports them from lib/yorha/name.sh of the version in use (YORHA_NAME, YORHA_CMD,
// YORHA_PRETTY); where the shell runs straight from the repository (the lab), the defaults apply.
Singleton {
    id: root

    readonly property string name: Quickshell.env("YORHA_NAME") || "yorha-shell"     // folders
    readonly property string cmd: Quickshell.env("YORHA_CMD") || "yorha"             // the command
    readonly property string pretty: Quickshell.env("YORHA_PRETTY") || "YoRHa-Shell" // what texts call it

    readonly property string home: Quickshell.env("HOME") || ""
    // $XDG_STATE_HOME/<name>: what the menus save (never the person's config).
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/" + name
    // $XDG_CONFIG_HOME/<name>: the person's own config (shell.json); the product never writes it.
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/" + name
    // $XDG_DATA_HOME/<name>: the installed versions (lib/yorha/name.sh's YORHA_HOME).
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || home + "/.local/share") + "/" + name
    // $XDG_RUNTIME_DIR/<name>: the supervisor's lock and pid, the once-per-login marks.
    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/" + name

    function statePath(file: string): string {
        return stateDir + "/" + file;
    }
    function configPath(file: string): string {
        return configDir + "/" + file;
    }
}
