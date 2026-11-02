pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../strings"

// Newer versions, for a shell installed with yorha (spec 014 US3, contracts/updater.md).
//   - installed: qs was started by `yorha shell start`, which sets YORHA_ROOT to the version's
//     folder. Anything else (the lab's ~/nier/ui) is "not-installed": nothing runs, nothing shows.
//   - check(): `<root>/bin/<cmd> update --check --json` (Product.cmd), 30 s after the start and then
//     every hour; it answers current, latest, available, channel and origin (spec 015). The last
//     check, the newest version and the one already announced live in <state>/updates.json.
//   - a newer version is announced once, as a system transmission whose click opens SYSTEM › Updates
//     (the showUpdates signal; shell.qml opens the menu).
//   - updateNow(): the configured terminal (Settings.terminal) runs `yorha update` in the open, as
//     Serpantinum does; yorha restarts the shell at the end.
// spec 015 (contracts/sinal.md):
//   - sign (Settings "updates.sign"): how a newer version stays on screen until the update. bar: the
//     top bar's ■ UPDATE <latest> (hud/UpdateTag); menu: NEW on the SYSTEM tab and on the Updates
//     row; both (default); login: the transmission again once per login (the lock
//     update-reminded-<latest> in Product.runtimeDir, by mkdir, as Sounds.sessionStart); off: only the
//     first transmission. Everything follows `available`, so it all goes away after the update.
//   - autoCheck (Settings "updates.autoCheck"): the 30 s and hourly timers run only with it on; off,
//     check() runs when SYSTEM › Updates opens (opened()) and from the IPC.
//   - updates.json also keeps `available` and the `current` it was found against, so a restarted
//     shell keeps the sign before its first check (or with the check off); a new version starts clean.
Singleton {
    id: root

    readonly property string rootDir: Quickshell.env("YORHA_ROOT") ?? ""
    readonly property bool installed: rootDir !== ""
    readonly property string yorha: installed ? rootDir + "/bin/" + Product.cmd : ""
    readonly property string current: installed ? String(versionFile.text()).trim() : ""
    // What the footers show: the installed version, or 0.1 where the shell runs from the repository
    // (the lab), so the lab's screenshots stay as they were.
    readonly property string versionLabel: current !== "" ? current : "0.1"
    property string latest: ""
    property bool available: false
    property string state: installed ? "idle" : "not-installed"    // idle | checking | error | not-installed
    property string error: ""
    property string notified: ""
    property real lastCheck: 0

    // spec 015: the sign's form and the automatic check, live from the options.
    readonly property string sign: Settings.updateSign
    readonly property bool autoCheck: Settings.updateAutoCheck
    readonly property bool signBar: available && (sign === "bar" || sign === "both")
    readonly property bool signMenu: available && (sign === "menu" || sign === "both")
    onSignChanged: remind()

    signal showUpdates()

    readonly property string statePath: Product.statePath("updates.json")

    // "" when it started; else why not.
    function check(): string {
        if (!installed)
            return "not installed with yorha";
        if (checker.running)
            return "a check is running";
        state = "checking";
        checker.running = true;
        return "ok";
    }

    function finish(code: int, text: string): void {
        let d = null;
        try {
            d = JSON.parse(text);
        } catch (e) {
        }
        lastCheck = Date.now();
        if (code !== 0 || !d || d.error) {
            state = "error";
            error = d?.error ?? `yorha exited with ${code}`;
            save();
            return;
        }
        state = "idle";
        error = "";
        latest = String(d.latest ?? "");
        available = d.available === true;
        if (available && latest !== notified) {
            notified = latest;
            announce();
            mark(latest);                // the first transmission counts as this login's reminder
        } else
            remind();
        save();
    }

    function announce(): void {
        NotifyStore.system(Strings.updates.noticeTitle, Strings.updates.noticeBody.arg(latest), "normal", false,
            () => root.showUpdates());
    }

    // spec 015, the `login` form: the transmission again, once per login, while a newer version exists.
    function remind(): void {
        if (!installed || !available || sign !== "login" || latest === "" || reminder.running)
            return;
        reminder.command = ["sh", "-c", 'mkdir -p "$1" && mkdir "$1/update-reminded-$2" 2>/dev/null', "sh", Product.runtimeDir, latest];
        reminder.running = true;
    }
    function mark(version: string): void {
        marker.command = ["sh", "-c", 'mkdir -p "$1/update-reminded-$2"', "sh", Product.runtimeDir, version];
        marker.running = true;
    }

    // spec 015 (FR-019): SYSTEM › Updates was opened (PauseMenu); with the automatic check off, check now.
    function opened(): void {
        if (installed && !autoCheck)
            check();
    }

    // The configured terminal runs `yorha update`; without one, a transmission says what to run.
    function updateNow(): string {
        if (!installed)
            return "not installed with yorha";
        const t = Settings.terminal;
        const bin = String(t[0] ?? "");
        const cmd = bin.split("/").pop() === "kitty" ? [...t, "--hold", yorha, "update"]
            : [...t, "-e", "sh", "-c", `"${yorha}" update; printf '\\n%s' "${Strings.updates.enterCloses}"; read -r _`];
        runner.command = ["sh", "-c", 'command -v "$1" >/dev/null || exit 127; shift; setsid -f "$@" >/dev/null 2>&1', "sh", bin, ...cmd];
        runner.running = true;
        return "ok";
    }

    // The texts of SYSTEM › Updates' rows.
    function text(row: string): string {
        const U = Strings.updates;
        if (row === "installed")
            return installed ? current : U.notInstalled;
        if (!installed)
            return U.notInstalled;
        if (state === "checking" && latest === "")
            return U.checking;
        if (state === "error" && latest === "")
            return U.couldNotCheck;
        return available ? latest : U.upToDate;
    }

    function dump(): string {
        return JSON.stringify({
            installed: installed, root: rootDir, current: current, latest: latest, available: available,
            state: state, error: error, notified: notified, lastCheck: lastCheck,
            installedText: text("installed"), availableText: text("available"),
            // spec 015 (contracts/sinal.md); shell.qml puts in what the bars really show
            sign: sign, autoCheck: autoCheck,
            timers: { first: firstTimer.running, hourly: hourlyTimer.running },
            signVisible: { bar: signBar, menuTab: signMenu, menuRow: signMenu }
        });
    }

    function save(): void {
        if (installed)
            stateFile.setText(JSON.stringify({ lastCheck: lastCheck, latest: latest, notified: notified,
                                               available: available, current: current }, null, 2) + "\n");
    }

    FileView {
        id: versionFile
        path: root.installed ? root.rootDir + "/VERSION" : ""
        blockLoading: true
        printErrors: false
    }
    // setText() writes atomically and creates the folder when needed.
    FileView {
        id: stateFile
        path: root.installed ? root.statePath : ""
        blockLoading: true
        printErrors: false          // no file yet is the normal first run
        atomicWrites: true
    }

    // The exit code and the end of the output can come in either order: finish when both are in.
    property int checkCode: -1
    property bool checkRead: false
    function checkPart(): void {
        if (checkCode < 0 || !checkRead)
            return;
        const code = checkCode;
        checkCode = -1;
        checkRead = false;
        finish(code, checkOut.text);
    }
    Process {
        id: checker
        command: [root.yorha, "update", "--check", "--json"]
        stdout: StdioCollector {
            id: checkOut
            onStreamFinished: {
                root.checkRead = true;
                root.checkPart();
            }
        }
        onExited: code => {
            root.checkCode = code;
            root.checkPart();
        }
    }
    Process {
        id: reminder
        onExited: code => {
            if (code === 0 && root.available && root.sign === "login")
                root.announce();
        }
    }
    Process {
        id: marker
    }
    Process {
        id: runner
        onExited: code => {
            if (code === 127)
                NotifyStore.system(Strings.updates.noTerminalTitle, Strings.updates.noTerminalBody.arg(root.yorha), "normal", false);
        }
    }
    // spec 015 (FR-019): only with the automatic check on.
    Timer {
        id: firstTimer
        interval: 30000
        running: root.installed && root.autoCheck
        onTriggered: root.check()
    }
    Timer {
        id: hourlyTimer
        interval: 3600000
        repeat: true
        running: root.installed && root.autoCheck
        onTriggered: root.check()
    }

    Component.onCompleted: {
        if (!installed)
            return;
        try {
            const d = JSON.parse(stateFile.text() || "{}");
            notified = String(d.notified ?? "");
            lastCheck = Number(d.lastCheck ?? 0);
            // spec 015: the newer version found by the last check, while this is still the same version
            if (d.available === true && String(d.current ?? "") === current && String(d.latest ?? "") !== "") {
                latest = String(d.latest);
                available = true;
            }
        } catch (e) {
        }
        remind();
    }
}
