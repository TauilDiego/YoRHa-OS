pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// After an update that changed the product's name (spec 015, FR-017, research R6): one transmission
// with the new line for hyprland.lua. The update leaves <state>/renamed-from (name=, pretty=, date=
// of the old name); the notice is given once per change, marked in <state>/renamed-announced (the
// change's name and date on the first line, then what was said). The person's old line keeps working
// (a compatibility file), so this only says what to put instead, and nothing when their hyprland.lua
// already has the new line (a rollback to the name they still use).
// The texts live here and not in Strings.qml while front B owns it (spec 015); the junction may move them.
Singleton {
    id: root

    readonly property bool installed: (Quickshell.env("YORHA_ROOT") ?? "") !== ""
    // The line the install prints, for this name (bin/yorha's include_line).
    readonly property string includeLine: {
        const f = Product.dataDir + "/current/system/hypr/" + Product.name + ".lua";
        const h = Product.home;
        return h !== "" && f.startsWith(h + "/") ? `pcall(dofile, os.getenv("HOME") .. "${f.slice(h.length)}")` : `pcall(dofile, "${f}")`;
    }
    property string from: ""            // the old name, once read
    property bool announced: false

    function value(text: string, key: string): string {
        const m = text.match(new RegExp("^" + key + "=(.*)$", "m"));
        return m ? m[1].trim() : "";
    }

    function announce(): void {
        if (!installed)
            return;
        fromFile.reload();
        markFile.reload();
        const t = String(fromFile.text() ?? "");
        from = value(t, "name");
        if (from === "")
            return;
        const key = from + " " + value(t, "date");
        if (String(markFile.text() ?? "").split("\n")[0].trim() === key) {
            announced = true;
            return;
        }
        hyprFile.reload();
        const needle = "/current/system/hypr/" + Product.name + ".lua";
        const hasLine = String(hyprFile.text() ?? "").split("\n").some(l => !l.trim().startsWith("--") && l.includes(needle));
        const old = value(t, "pretty") || from;
        const title = `${old} is now ${Product.pretty}`;
        const body = `Your hyprland.lua line still works. When you can, replace it with:\n${includeLine}`
            + (value(t, "cmd") !== "" && value(t, "cmd") !== Product.cmd ? `\nThe command is now ${Product.cmd} (${value(t, "cmd")} still works).` : "");
        if (!hasLine)
            NotifyStore.system(title, body, "normal", false);
        markFile.setText(key + "\n" + (hasLine ? "(not shown: hyprland.lua already has the line)" : title + "\n" + body) + "\n");
        announced = true;
    }

    FileView {
        id: fromFile
        path: root.installed ? Product.statePath("renamed-from") : ""
        blockLoading: true
        printErrors: false          // no file: no change of name, the normal case
    }
    FileView {
        id: hyprFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || Product.home + "/.config") + "/hypr/hyprland.lua"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: markFile
        path: root.installed ? Product.statePath("renamed-announced") : ""
        blockLoading: true
        printErrors: false
        atomicWrites: true
    }
    // A moment after the start, so the transmission shows over a desktop that is up.
    Timer {
        interval: 3000
        running: root.installed
        onTriggered: root.announce()
    }
}
