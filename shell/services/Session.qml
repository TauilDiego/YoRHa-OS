pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../strings"

// Session and power for the pause menu's POWER tab (spec 007, contracts/services.md, research R9):
// what the machine can do, who holds it, the session's status, and the actions themselves.
// actions: [{ id, label, confirm, available, reason, blockers: [{ who, why }], effect }], in the
// list's order. status: { user, host, uptime (s), battery ({ percent, charging } or null), windows,
// note }.
// SAFETY: with ANY fixture active (`dryRun`) no action ever runs: run() only records it.
// Fixture "session": the path of a file (pause-fixtures.schema.json, sessionFile).
Singleton {
    id: root

    readonly property var ids: ["lock", "logout", "suspend", "hibernate", "reboot", "poweroff"]
    readonly property bool dryRun: Fixtures.active
    readonly property bool fixed: Fixtures.has("session")
    readonly property string fixturePath: fixed ? Fixtures.resolve(String(Fixtures.get("session") ?? "")) : ""

    // What the machine says: can.{suspend,hibernate,reboot,poweroff} = yes|challenge|no|na, and the
    // inhibitors [{ what, who, why, mode }]. From the fixture, or from logind (frente C).
    property var can: ({})
    property var inhibitors: []
    property var refuse: []                      // fixture only: ids that answer as refused
    property string user: ""
    property string host: ""
    property int uptime: 0
    property string fixtureError: ""

    property string busy: ""                     // the action between run() and the answer
    property var lastAction: null                // { id, executed, ok }
    property string lastError: ""                // the last refusal, until the next action

    signal accepted(string id)
    signal refused(string id, string reason)

    readonly property string error: fixed && fixtureError !== "" ? Strings.pause.sessionError : ""
    readonly property string confirmMode: SettingsModel.choiceId("menu", "confirm") || "risky"

    function closesSession(id: string): bool {
        return id === "logout" || id === "reboot" || id === "poweroff";
    }

    function availability(id: string): var {
        if (id === "lock" || id === "logout")
            return { available: true, reason: "" };
        const v = String(can[id] ?? "na");
        if (v === "yes" || v === "challenge")
            return { available: true, reason: "" };
        return { available: false, reason: v === "no" ? Strings.pause.notAllowed : Strings.pause.notSupported };
    }

    // The block-mode inhibitors that stop `id`: shutdown for log out, reboot and shut down; sleep
    // for suspend and hibernate.
    function blockersOf(id: string): var {
        const what = closesSession(id) ? "shutdown" : (id === "suspend" || id === "hibernate") ? "sleep" : "";
        if (what === "")
            return [];
        return inhibitors.filter(i => i.mode === "block" && String(i.what).split(":").includes(what))
                         .map(i => ({ who: String(i.who), why: String(i.why) }));
    }

    readonly property var actions: {
        const n = Compositor.windows.length;
        return ids.map(id => {
            const av = availability(id);
            return {
                id: id,
                label: Strings.pause.powerLabels[id],
                confirm: confirmMode === "all" || closesSession(id),
                available: av.available,
                reason: av.reason,
                blockers: blockersOf(id),
                effect: !closesSession(id) ? Strings.pause.sessionStays
                      : n === 0 ? Strings.pause.noWindowWillClose
                      : n === 1 ? Strings.pause.oneWindowWillClose : Strings.pause.windowsWillClose.arg(n)
            };
        });
    }

    function actionOf(id: string): var {
        return actions.find(a => a.id === id) ?? null;
    }

    readonly property var status: {
        const bat = Battery.bat;
        const b = bat.available ? { percent: Math.round(bat.value * 100), charging: bat.extra === "charging" } : null;
        const block = inhibitors.find(i => i.mode === "block");
        return {
            user: user,
            host: host,
            uptime: uptime,
            battery: b,
            windows: Compositor.windows.length,
            note: lastError !== "" ? lastError : error !== "" ? error
                : block ? Strings.pause.holding.arg(block.who).arg(block.why) : ""
        };
    }

    // Re-read what the machine can do and who holds it (entering POWER, opening the dialog).
    function refresh(): void {
        if (fixed)
            return;
        refreshLive();
    }

    // Run action `id` (research R9). Under any fixture, only recorded.
    function run(id: string): void {
        const a = actionOf(id);
        if (!a || !a.available || busy !== "")
            return;
        lastError = "";
        if (dryRun) {
            const no = refuse.includes(id);
            lastAction = { id: id, executed: false, ok: !no };
            if (no)
                refuse_(id, Strings.pause.notAllowed);
            else
                accepted(id);
            return;
        }
        runLive(id);
    }

    // A refusal: the error stays on the card until the next action. An action that closed the menu
    // first (lock, suspend, hibernate) says so on the next opening, and in the log.
    function refuse_(id: string, reason: string): void {
        if (closesSession(id)) {
            lastError = Strings.pause.refused.arg(reason);
        } else {
            lastError = Strings.pause.lastRefused.arg(Strings.pause.powerLabels[id]).arg(reason);
            console.info(`session: ${id} refused: ${reason}`);
        }
        refused(id, reason);
    }

    // --- the real sources (research R9) --------------------------------------------------------------
    // Every program is called by argv, never through a shell. Capabilities and inhibitors are read
    // again on refresh() only (entering POWER, opening the dialog), never polled.
    readonly property var capQueries: [
        { id: "suspend", method: "CanSuspend" },
        { id: "hibernate", method: "CanHibernate" },
        { id: "reboot", method: "CanReboot" },
        { id: "poweroff", method: "CanPowerOff" }
    ]

    function busctl(method: string): var {
        return ["busctl", "--json=short", "call", "org.freedesktop.login1", "/org/freedesktop/login1",
                "org.freedesktop.login1.Manager", method];
    }

    function refreshLive(): void {
        user = Quickshell.env("USER") ?? "";
        refuse = [];
        fixtureError = "";
        readStatus();
        for (let i = 0; i < capRepeater.count; i++) {
            const p = capRepeater.objectAt(i);
            if (p && !p.running)
                p.running = true;
        }
        if (!inhibitorQuery.running)
            inhibitorQuery.running = true;
    }

    // Host and uptime (the status card; uptime again every minute while POWER is shown).
    function readStatus(): void {
        if (fixed)
            return;
        if (!statusQuery.running)
            statusQuery.running = true;
    }

    function parseStatus(text: string): void {
        if (fixed)                               // a fixture came in meanwhile, and wins
            return;
        const lines = text.split("\n");
        const up = parseFloat(lines[0]);
        if (isFinite(up))
            uptime = Math.floor(up);
        if ((lines[1] ?? "").trim() !== "")
            host = lines[1].trim();
    }

    function parseCan(id: string, text: string): void {
        if (fixed)                               // a fixture came in meanwhile, and wins
            return;
        try {
            const v = String(JSON.parse(text).data[0]);
            const next = Object.assign({}, can);
            next[id] = v;
            can = next;
        } catch (e) {
            console.info(`session: Can ${id} unreadable, keeping "${can[id] ?? "na"}": ${e}`);
        }
    }

    function parseInhibitors(text: string): void {
        if (fixed)                               // a fixture came in meanwhile, and wins
            return;
        try {
            inhibitors = JSON.parse(text).data[0].map(i => ({
                what: String(i[0]), who: String(i[1]), why: String(i[2]), mode: String(i[3])
            }));
        } catch (e) {
            console.info(`session: ListInhibitors unreadable, keeping the last list: ${e}`);
        }
    }

    // The argv of an action; log out asks uwsm first (logout() below).
    function commandOf(id: string): var {
        switch (id) {
        case "lock":
            return ["loginctl", "lock-session"];
        case "suspend":
        case "hibernate":
        case "reboot":
        case "poweroff":
            return ["systemctl", id];
        }
        return [];
    }

    // Lock, suspend and hibernate close the menu before they run: a short wait lets the compositor
    // take the pop-up off the screen first (FR-023).
    function runLive(id: string): void {
        busy = id;
        pendingId = id;
        if (closesSession(id))
            startLive();
        else
            clearScreen.restart();
    }

    property string pendingId: ""

    function startLive(): void {
        const id = pendingId;
        if (id === "logout") {
            uwsmCheck.running = true;
            return;
        }
        launch(commandOf(id));
    }

    function launch(argv: var): void {
        actionProc.exitCode = -1;
        actionProc.errDone = false;
        actionProc.exited_ = false;
        actionProc.command = argv;
        actionProc.running = true;
    }

    function finishLive(code: int, err: string): void {
        const id = pendingId;
        pendingId = "";
        busy = "";
        lastAction = { id: id, executed: true, ok: code === 0 };
        if (code === 0) {
            accepted(id);
            return;
        }
        const reason = err.trim().split("\n")[0] || Strings.pause.notAllowed;
        console.info(`session: ${actionProc.command.join(" ")} exited with ${code}: ${reason}`);
        refuse_(id, reason);
    }

    Timer {
        id: clearScreen
        interval: 150
        onTriggered: root.startLive()
    }

    Process {
        id: statusQuery
        command: ["cat", "/proc/uptime", "/proc/sys/kernel/hostname"]
        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(text)
        }
    }

    Instantiator {
        id: capRepeater
        model: root.capQueries
        delegate: Process {
            required property var modelData
            command: root.busctl(modelData.method)
            stdout: StdioCollector {
                onStreamFinished: root.parseCan(modelData.id, text)
            }
        }
    }

    Process {
        id: inhibitorQuery
        command: root.busctl("ListInhibitors")
        stdout: StdioCollector {
            onStreamFinished: root.parseInhibitors(text)
        }
    }

    // A uwsm session ends by `uwsm stop`; any other, by logind.
    Process {
        id: uwsmCheck
        command: ["uwsm", "check", "is-active"]
        onExited: code => root.launch(code === 0 ? ["uwsm", "stop"]
            : ["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID") || "self"])
    }

    // The action itself: done once it has exited and its stderr is read.
    Process {
        id: actionProc
        property int exitCode: -1
        property bool exited_: false
        property bool errDone: false
        function settle(): void {
            if (exited_ && errDone)
                root.finishLive(exitCode, actionErr.text);
        }
        stderr: StdioCollector {
            id: actionErr
            onStreamFinished: {
                actionProc.errDone = true;
                actionProc.settle();
            }
        }
        onExited: code => {
            exitCode = code;
            exited_ = true;
            settle();
        }
    }

    Component.onCompleted: if (!fixed) refreshLive()

    // --- the fixture ---------------------------------------------------------------------------------
    function loadFixture(text: string): void {
        try {
            const d = JSON.parse(text);
            if (typeof d?.user !== "string" || typeof d.host !== "string" || !Number.isInteger(d.uptime) || typeof d.can !== "object")
                throw new Error("needs user, host, uptime and can");
            user = d.user;
            host = d.host;
            uptime = d.uptime;
            can = d.can;
            inhibitors = Array.isArray(d.inhibitors) ? d.inhibitors : [];
            refuse = Array.isArray(d.refuse) ? d.refuse : [];
            fixtureError = "";
        } catch (e) {
            failFixture(`${fixturePath}: ${e}`);
        }
    }

    function failFixture(reason: string): void {
        console.warn(`session: fixture unusable, ${reason}`);
        can = {};
        inhibitors = [];
        refuse = [];
        user = "";
        host = "";
        uptime = 0;
        fixtureError = reason;
    }

    // Back to the start (a fixture loaded again, `pause reset`).
    function resetFixture(): void {
        lastAction = null;
        lastError = "";
        busy = "";
        if (fixed)
            fixtureFile.reload();
        else
            refreshLive();
    }

    FileView {
        id: fixtureFile
        path: root.fixturePath
        printErrors: false
        blockLoading: true
        onLoaded: root.loadFixture(text())
        onLoadFailed: root.failFixture(`cannot read ${path}`)
    }

    onFixedChanged: resetFixture()

    Connections {
        target: Fixtures
        function onDataChanged(): void {
            root.resetFixture();
        }
    }
}
