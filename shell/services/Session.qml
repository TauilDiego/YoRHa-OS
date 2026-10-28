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
            if (no) {
                lastError = Strings.pause.refused.arg(Strings.pause.notAllowed);
                refused(id, Strings.pause.notAllowed);
            } else {
                accepted(id);
            }
            return;
        }
        runLive(id);
    }

    // --- the real sources (frente C) -----------------------------------------------------------------
    function refreshLive(): void {
    }

    function runLive(id: string): void {
    }

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
