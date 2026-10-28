pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../ds"
import "../strings"

// The notification server, the text log and what is on screen (spec 008, contracts/services.md,
// data-model.md). The shell owns org.freedesktop.Notifications (research R1); every notification
// becomes an Entry in the log (newest first, at most NotifyPrefs.logSize, transient ones excepted)
// and, unless held (do not disturb, a held full-screen window, the log open), a transmission on
// screen: on the stack (at most NotifyPrefs.onScreen per monitor, the newest first) or, if
// critical, on the critical band. Leaving the screen never closes a notification for its app
// (FR-008): only the user (dismiss, Clear all) or the app do.
//   Arrivals are queued and applied once per frame (R18): `entries` and `stack` are reassigned once
// per batch. Times are planned, not ticked: a transmission's typing ends at `typedAt` (the same
// duration its TypedText animates), then it stays NotifyText.duration() ms, paused while the
// pointer is over it or its reply field is open; one Timer fires at the next deadline.
//   With fixtures (the "notifications" domain, contracts/notifications.schema.json) the log, the
// stack and the critical band come from the file, frozen: nothing types, nothing expires, nothing is
// written. Notifications that still arrive over D-Bus show whole, without a time.
//   The session's log survives a reload of the shell (PersistentProperties, R15); with Text log:
// Saved it is also written to $XDG_STATE_HOME/rien-os/text-log.json, mode 600 (R14).
Singleton {
    id: root

    // --- public state (contracts/services.md) --------------------------------------------------------
    property var entries: []                   // Entry objects, newest first
    property var stack: []                     // Transmission records, newest first (all monitors)
    property var critical: null                // { ids: [newest first], page, monitor } or null
    property int overflow: 0                   // "+N in log"
    property bool logOpen: false               // set by shell.qml (the pop-up) or the pause menu (007)
    readonly property bool held: NotifyPrefs.dnd || (Compositor.focusedFullscreen && NotifyPrefs.fullscreen === "hold")
    readonly property bool fixed: Fixtures.has("notifications")
    readonly property var fixture: fixed ? (Fixtures.get("notifications") ?? {}) : null
    readonly property bool frozen: Tokens.frozen
    readonly property bool instantTyping: Tokens.instant || !NotifyPrefs.typing
    property bool liveServer: false
    property string serverOwner: ""
    readonly property bool server: fixed ? fixture.server !== false : liveServer
    // Unread: in the log, not read, and not on screen right now (the bar's counter, FR-025).
    readonly property int unread: {
        let n = 0;
        for (const e of entries)
            if (!e.read && !isShown(e.id))
                n++;
        return n;
    }
    property int revision: 0                   // bumped on every change (views that cache)

    readonly property string statePath: {
        const xdg = Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state");
        return xdg + "/rien-os/text-log.json";
    }
    readonly property bool saving: NotifyPrefs.log === "saved" && !fixed

    // --- lookups -------------------------------------------------------------------------------------
    // An entry of the log, or of a transient transmission (on screen only).
    function entry(id: int): var {
        return entries.find(e => e.id === id) ?? stack.find(t => t.id === id)?.entry ?? null;
    }
    function isShown(id: int): bool {
        return stack.some(t => t.id === id) || (critical?.ids.includes(id) ?? false);
    }
    function txOf(id: int): var {
        return stack.find(t => t.id === id) ?? null;
    }
    function stackOn(monitor: string): var {
        return stack.filter(t => t.monitor === monitor);
    }
    function speakerOf(e: var): string {
        if (!e)
            return "";
        return e.system ? NotifyPrefs.voiceName : (e.app || Strings.notify.unknown);
    }

    // --- the server (R1, R2) ---------------------------------------------------------------------------
    property var live: ({})                    // id → Notification (tracked), not persisted

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        inlineReplySupported: true
        onNotification: n => root.arrive(n)
    }

    // Who owns org.freedesktop.Notifications: us (our pid) or another program.
    Process {
        id: ownerQuery
        command: ["busctl", "--user", "status", "org.freedesktop.Notifications"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pid = Number((/^PID=(\d+)/m.exec(text) ?? [])[1] ?? 0);
                const comm = (/^Comm=(.*)$/m.exec(text) ?? [])[1] ?? "";
                const was = root.liveServer;
                root.liveServer = pid === Quickshell.processId;
                root.serverOwner = comm;
                if (!root.liveServer && (was || !root.ownerReported)) {
                    root.ownerReported = true;
                    console.info(`notifications: another program owns org.freedesktop.Notifications (${comm || "nobody"}, pid ${pid}); transmissions stay off`);
                    if (!root.fixed)
                        root.system(Strings.notify.serverMissing, Strings.notify.serverMissingText.arg(comm || "?"), "low", true);
                }
            }
        }
    }
    property bool ownerReported: false
    Timer {
        id: ownerTimer
        interval: root.liveServer ? 60000 : (root.ownerChecks < 1 ? 500 : 30000)
        running: true
        repeat: true
        onTriggered: {
            root.ownerChecks++;
            ownerQuery.running = true;
        }
    }
    property int ownerChecks: 0
    function refreshOwner(): void {
        if (!ownerQuery.running)
            ownerQuery.running = true;
    }

    // --- entries -----------------------------------------------------------------------------------------
    property int systemSeq: 0

    function urgencyOf(n: var): string {
        return n.urgency === NotificationUrgency.Critical ? "critical" : n.urgency === NotificationUrgency.Low ? "low" : "normal";
    }
    function appOf(n: var): string {
        if (n.appName)
            return n.appName;
        if (n.desktopEntry)
            return DesktopEntries.byId(n.desktopEntry)?.name || n.desktopEntry;
        return "";
    }
    // Entry fields from a live Notification (data-model "Entry").
    function fieldsOf(n: var): var {
        const acts = [];
        let hasDefault = false;
        let defaultLabel = "";
        for (const a of n.actions) {
            if (a.identifier === "default") {
                hasDefault = true;
                defaultLabel = a.text;
            }
            else if (a.identifier !== "inline-reply")
                acts.push({ id: a.identifier, label: a.text });
        }
        const v = n.hints?.value;
        return {
            app: appOf(n),
            appKey: n.desktopEntry || n.appName || "",
            title: NotifyText.plain(n.summary).replace(/\s+/g, " ").trim(),
            body: NotifyText.sanitize(n.body),
            urgency: urgencyOf(n),
            timeout: n.expireTimeout > 0 ? n.expireTimeout : null,
            actions: acts,
            hasDefault: hasDefault,
            defaultLabel: defaultLabel,
            reply: n.hasInlineReply ? { label: n.inlineReplyPlaceholder || Strings.notify.reply } : null,
            progress: Number.isInteger(v) ? Math.max(0, Math.min(100, v)) : (typeof v === "number" ? Math.round(Math.max(0, Math.min(100, v))) : null),
            resident: n.resident,
            transient: n.transient
        };
    }
    function makeEntry(id: int, f: var, at: real): var {
        return Object.assign({
            id: id, app: "", appKey: "", system: false, title: "", body: "", urgency: "normal", timeout: null,
            actions: [], hasDefault: false, defaultLabel: "", reply: null, image: "", progress: null, resident: false, transient: false,
            at: at, read: false, isNew: false, answered: "", alive: true, earlier: false, typedFrom: 0
        }, f);
    }

    property var queue: []

    function arrive(n: var): void {
        n.tracked = true;
        live[n.id] = n;
        n.closed.connect(reason => root.closedByServer(n.id, reason));
        for (const sig of [n.summaryChanged, n.bodyChanged, n.actionsChanged, n.hintsChanged, n.imageChanged, n.urgencyChanged])
            sig.connect(() => root.noteReplace(n.id));
        if (n.lastGeneration) {
            // Re-emitted after a reload of the shell: bind it to its entry again, don't show it (R15).
            const e = entries.find(x => x.id === n.id);
            if (e) {
                e.alive = true;
                commit(false);
            } else {
                queue = queue.concat([{ n: n, at: Date.now(), quiet: true }]);
                batch.restart();
            }
            return;
        }
        queue = queue.concat([{ n: n, at: Date.now() }]);
        if (!batch.running)
            batch.start();
    }

    Timer {
        id: batch
        interval: Tokens.notify.batchMs
        onTriggered: root.applyBatch()
    }

    // The queued arrivals, at once (R18).
    function applyBatch(): void {
        const items = queue;
        queue = [];
        const now = Date.now();
        for (const q of items) {
            const n = q.n;
            const e = makeEntry(n.id, fieldsOf(n), q.at);
            checkImage(e, n.image);
            if (q.quiet)
                e.read = true;
            if (!e.transient)
                entries.unshift(e);
            if (!q.quiet)
                place(e, q.at, now);
        }
        trimLog();
        commit(true);
    }

    // A rien-OS message, spoken with the system's voice (R17): no app to tell.
    function system(title: string, body: string, urgency: string, quiet: bool): int {
        const id = -1000 - (++systemSeq);
        const e = makeEntry(id, {
            system: true, title: title, body: NotifyText.sanitize(body),
            urgency: ["low", "normal", "critical"].includes(urgency) ? urgency : "normal", alive: false
        }, Date.now());
        entries.unshift(e);
        if (!quiet)
            place(e, e.at, Date.now());
        trimLog();
        commit(true);
        return id;
    }

    // Where a new entry goes: the critical band, the log (held), or the stack (grouped).
    function place(e: var, arrivedAt: real, now: real): void {
        if (e.urgency === "critical") {
            const mon = critical?.monitor ?? monitorFor();
            critical = { ids: [e.id].concat((critical?.ids ?? []).filter(x => x !== e.id)), page: 0, monitor: mon };
            e.read = true;
            return;
        }
        if (logOpen) {
            e.read = true;
            e.isNew = true;
            return;
        }
        if (held) {
            e.read = false;
            return;
        }
        // The same app with a transmission on screen: that transmission shows the newest (FR-017).
        const same = e.appKey !== "" ? stack.find(t => t.appKey === e.appKey && !t.replying) : null;
        if (same) {
            const prev = entries.find(x => x.id === same.id);
            if (prev)
                prev.read = true;
            same.ids.push(e.id);
            same.id = e.id;
            same.entry = e;
            same.count++;
            same.from = NotifyText.firstDiff(prev?.body ?? "", e.body);
            startTyping(same, now);
            stack = [same].concat(stack.filter(t => t !== same));
            return;
        }
        const t = {
            key: "t" + (++txSeq), id: e.id, ids: [e.id], entry: e, appKey: e.appKey, count: 1, monitor: monitorFor(),
            arrivedAt: arrivedAt, shownAt: now, typedAt: now, typed: false, from: 0,
            expiresAt: null, remaining: null, total: null, paused: false, hover: false, replying: false
        };
        startTyping(t, now);
        stack = [t].concat(stack);
        enforceLimit();
    }
    property int txSeq: 0

    // The monitor a new transmission goes to (FR-004): the fixed one if it exists, else the focused.
    function monitorFor(): string {
        const names = Quickshell.screens.map(sc => sc.name);
        if (NotifyPrefs.monitor !== "" && names.includes(NotifyPrefs.monitor))
            return NotifyPrefs.monitor;
        const f = Compositor.focusedMonitor;
        return names.includes(f) ? f : (names[0] ?? "");
    }

    // Typing (FR-006): from `t.from` to the end at Tokens.notify.cps, never longer than typeMaxMs.
    function typeMs(e: var, from: int): int {
        if (instantTyping || fixed)
            return 0;
        const n = NotifyText.visibleLength(e?.body ?? "");
        if (n <= from)
            return 0;
        return Math.min(Tokens.notify.typeMaxMs, Math.round((n - from) / Tokens.notify.cps * 1000));
    }
    function startTyping(t: var, now: real): void {
        t.typed = false;
        t.typedAt = now + typeMs(t.entry, t.from);
        t.expiresAt = null;
        t.total = null;
        t.remaining = null;
        settle(now);
    }

    // The stack over its limit: the oldest (per monitor) go to the log, unread when not typed out (FR-018).
    function enforceLimit(): void {
        const keep = [];
        const perMon = {};
        let out = 0;
        for (const t of stack) {
            perMon[t.monitor] = (perMon[t.monitor] ?? 0) + 1;
            if (perMon[t.monitor] <= NotifyPrefs.onScreen) {
                keep.push(t);
                continue;
            }
            if (!t.typed) {
                t.entry.read = false;
                out++;
            } else {
                t.entry.read = true;
            }
        }
        if (keep.length !== stack.length) {
            stack = keep;
            overflow += out;
        }
    }

    // --- time (FR-007): typed → read, then the transmission's time; one Timer at the next deadline -----
    function settle(now: real): void {
        let changed = false;
        const keep = [];
        for (const t of stack) {
            if (!t.typed && now >= t.typedAt) {
                t.typed = true;
                t.entry.read = true;
                t.total = fixed ? null : NotifyText.duration(t.entry, NotifyPrefs.durationFactor);
                if (t.total !== null) {
                    if (t.paused)
                        t.remaining = t.total;
                    else
                        t.expiresAt = now + t.total;
                }
                changed = true;
            }
            if (t.typed && t.expiresAt !== null && !t.paused && now >= t.expiresAt) {
                changed = true;
                continue;                        // timed out: off the screen, still in the log
            }
            keep.push(t);
        }
        if (keep.length !== stack.length) {
            stack = keep;
            if (stack.length === 0)
                overflow = 0;
        }
        if (changed)
            commit(false);
        schedule(now);
    }
    function schedule(now: real): void {
        let next = Infinity;
        for (const t of stack) {
            if (!t.typed)
                next = Math.min(next, t.typedAt);
            else if (t.expiresAt !== null && !t.paused)
                next = Math.min(next, t.expiresAt);
        }
        if (next === Infinity) {
            clock.stop();
            return;
        }
        clock.interval = Math.max(1, Math.ceil(next - now));
        clock.restart();
    }
    Timer {
        id: clock
        onTriggered: root.settle(Date.now())
    }

    // The pointer over a transmission (or its reply field open): the text completes and the time stops.
    function pause(id: int, on: bool): void {
        const t = txOf(id);
        if (!t)
            return;
        const now = Date.now();
        t.hover = on;
        const want = on || t.replying;
        if (want && !t.typed)
            t.typedAt = now;                     // hover completes the typing (FR-006)
        if (want === t.paused) {
            settle(now);
            return;
        }
        t.paused = want;
        if (want) {
            if (t.typed && t.expiresAt !== null)
                t.remaining = Math.max(0, t.expiresAt - now);
            t.expiresAt = null;
        } else if (t.typed && t.remaining !== null) {
            t.expiresAt = now + t.remaining;
            t.remaining = null;
        }
        settle(now);
        commit(false);
    }
    // The view says the typing is done (or the user completed it).
    function typed(id: int): void {
        const t = txOf(id);
        if (t && !t.typed) {
            t.typedAt = Date.now();
            settle(t.typedAt);
        }
    }
    // Remaining ms of transmission `id` (null: no time, critical or fixtures).
    function remainingOf(id: int): var {
        const t = txOf(id);
        if (!t || fixed)
            return null;
        if (!t.typed)
            return NotifyText.duration(t.entry, NotifyPrefs.durationFactor);
        if (t.total === null)
            return null;
        return t.paused ? t.remaining : Math.max(0, Math.round(t.expiresAt - Date.now()));
    }
    // How many characters of the body are visible now (the dump).
    function shownOf(t: var): int {
        const n = NotifyText.visibleLength(t.entry?.body ?? "");
        if (t.typed)
            return n;
        const span = t.typedAt - t.shownAt;
        const k = span <= 0 ? 1 : Math.max(0, Math.min(1, (Date.now() - t.shownAt) / span));
        return Math.round(t.from + (n - t.from) * k);
    }
    // The reply field (FR-014): one transmission at a time; its time stops while it is open.
    function setReplying(id: int, on: bool): void {
        for (const t of stack)
            if (t.replying && t.id !== id) {
                t.replying = false;
                pause(t.id, t.hover);
            }
        const t = txOf(id);
        if (!t)
            return;
        t.replying = on;
        pause(id, t.hover);
        commit(false);
    }
    readonly property bool replying: stack.some(t => t.replying)

    // --- actions (US3, FR-008, FR-013) ----------------------------------------------------------------
    function invoke(id: int, actionId: string): string {
        const e = entry(id);
        if (!e)
            return `error: no notification ${id}`;
        if (!e.alive || e.earlier)
            return "error: the app closed this notification";
        const n = live[id];
        if (n) {
            const a = n.actions.find(x => x.identifier === actionId);
            if (!a)
                return `error: no action ${actionId}`;
            a.invoke();
        } else if (actionId !== "default" && !e.actions.some(a => a.id === actionId)) {
            return `error: no action ${actionId}`;
        }
        e.answered = actionId;
        e.read = true;
        if (!e.resident)
            e.alive = false;
        takeOff(id);
        commit(true);
        return "ok";
    }
    function reply(id: int, text: string): string {
        const e = entry(id);
        if (!e)
            return `error: no notification ${id}`;
        if (!e.reply || !e.alive)
            return "error: this notification takes no reply";
        const n = live[id];
        if (n)
            n.sendInlineReply(text);
        e.answered = "reply";
        e.read = true;
        e.alive = false;
        const t = txOf(id);
        if (t)
            t.replying = false;
        takeOff(id);
        commit(true);
        return "ok";
    }
    // Off the screen only (FR-008): the click without a default action, the right click, the ×.
    function hide(id: int): void {
        const e = entry(id);
        if (e)
            e.read = true;
        takeOff(id);
        commit(false);
    }
    function takeOff(id: int): void {
        const t = stack.find(x => x.id === id || x.ids.includes(id));
        if (t && t.id === id) {
            stack = stack.filter(x => x !== t);
            if (stack.length === 0)
                overflow = 0;
        }
        if (critical?.ids.includes(id)) {
            const ids = critical.ids.filter(x => x !== id);
            critical = ids.length === 0 ? null : { ids: ids, page: Math.min(critical.page, ids.length - 1), monitor: critical.monitor };
        }
        schedule(Date.now());
    }
    function hideAll(): void {
        for (const t of stack)
            t.entry.read = t.entry.read || t.typed;
        stack = [];
        critical = null;
        overflow = 0;
        schedule(Date.now());
        commit(false);
    }
    // The user dismisses an entry: the app is told, and it leaves the log (and the screen).
    function dismiss(id: int): void {
        const n = live[id];
        if (n)
            n.dismiss();
        takeOff(id);
        entries = entries.filter(e => e.id !== id);
        commit(true);
    }
    // Clear all: every live one dismissed, the log emptied (and its file, with Saved).
    function clear(): void {
        for (const id of Object.keys(live))
            live[id]?.dismiss();
        entries = [];
        stack = [];
        critical = null;
        overflow = 0;
        schedule(Date.now());
        commit(true);
    }
    // The critical band's pages (◂ ▸).
    function pageStep(dir: int): void {
        if (!critical)
            return;
        const p = Math.max(0, Math.min(critical.ids.length - 1, critical.page + dir));
        critical = { ids: critical.ids, page: p, monitor: critical.monitor };
    }

    // The app closed it (or we did): it stays in the log, its actions dimmed (FR-008, FR-023).
    function closedByServer(id: int, reason: int): void {
        delete live[id];
        const e = entries.find(x => x.id === id);
        if (e)
            e.alive = false;
        if (reason === NotificationCloseReason.CloseRequested) {
            const t = txOf(id);
            if (t || critical?.ids.includes(id))
                takeOff(id);
        }
        commit(false);
    }

    // A replacement (replaces_id) changes the same object (R4): the entry and its transmission change
    // in place; the typing starts again from the first character that differs (FR-006, FR-016).
    property var replacing: ({})
    function noteReplace(id: int): void {
        replacing[id] = true;
        Qt.callLater(root.applyReplaces);
    }
    function applyReplaces(): void {
        const ids = Object.keys(replacing).map(Number);
        replacing = {};
        const now = Date.now();
        for (const id of ids) {
            const n = live[id];
            const e = entries.find(x => x.id === id);
            if (!n || !e)
                continue;
            const before = e.body;
            Object.assign(e, fieldsOf(n));
            checkImage(e, n.image);
            e.typedFrom = NotifyText.firstDiff(before, e.body);
            const t = txOf(id);
            if (t) {
                t.from = e.typedFrom;
                startTyping(t, now);
            }
        }
        commit(true);
    }

    // --- images (R6): a file must really be a picture (Image logs a WARN for one it can't decode) -----
    property var imageQueue: []
    function checkImage(e: var, image: string): void {
        e.image = "";
        if (!image)
            return;
        if (image.startsWith("image://qsimage/")) {
            e.image = image;
            return;
        }
        const path = image.startsWith("image://icon/") ? image.slice(13)
                   : image.startsWith("file://") ? decodeURIComponent(image.slice(7)) : image;
        if (!path.startsWith("/")) {
            console.info(`notifications: ${e.app || "an app"} sent an icon name for an image (${path}), ignoring it`);
            return;
        }
        imageQueue = imageQueue.concat([{ id: e.id, path: path }]);
        if (!imageProbe.running)
            nextImage();
    }
    function nextImage(): void {
        if (imageQueue.length === 0)
            return;
        imageProbe.item = imageQueue[0];
        imageQueue = imageQueue.slice(1);
        imageProbe.command = ["file", "--brief", "--mime-type", "--", imageProbe.item.path];
        imageProbe.running = true;
    }
    Process {
        id: imageProbe
        property var item: null
        stdout: StdioCollector {
            onStreamFinished: {
                const it = imageProbe.item;
                const e = it ? root.entries.find(x => x.id === it.id) : null;
                if (e) {
                    if (["image/png", "image/jpeg", "image/webp"].includes(text.trim()))
                        e.image = "file://" + it.path;
                    else
                        console.info(`notifications: ${e.app || "an app"} sent an image that isn't a picture (${it.path}: ${text.trim()}), ignoring it`);
                    root.commit(false);
                }
            }
        }
        onExited: Qt.callLater(root.nextImage)
    }

    // --- the log ----------------------------------------------------------------------------------------
    function trimLog(): void {
        const max = NotifyPrefs.logSize;
        if (entries.length <= max)
            return;
        for (const e of entries.slice(max))
            live[e.id]?.expire();                // gone from the log: nothing can act on it any more
        entries = entries.slice(0, max);
    }
    // Opening the log marks everything read (FR-024); NEW stays while it is open.
    function markAllRead(): void {
        for (const e of entries) {
            e.isNew = e.isNew || !e.read;
            e.read = true;
        }
        overflow = 0;
        commit(false);
    }
    onLogOpenChanged: {
        if (logOpen) {
            markAllRead();
        } else {
            for (const e of entries)
                e.isNew = false;
            commit(false);
        }
    }

    // Every change ends here: the arrays are reassigned (bindings), the session and the file follow.
    function commit(save: bool): void {
        entries = entries.slice();
        stack = stack.slice();
        revision++;
        if (!fixed)
            Qt.callLater(root.saveSession);
        if (save && saving)
            saveTimer.restart();
    }

    // --- options that act on what is on screen (FR-041) -----------------------------------------------
    Connections {
        target: NotifyPrefs
        function onOnScreenChanged(): void {
            root.enforceLimit();
            root.commit(false);
        }
        function onMonitorChanged(): void {
            const m = root.monitorFor();
            for (const t of root.stack)
                t.monitor = m;
            if (root.critical)
                root.critical = { ids: root.critical.ids, page: root.critical.page, monitor: m };
            root.enforceLimit();
            root.commit(false);
        }
        function onLogSizeChanged(): void {
            root.trimLog();
            root.commit(true);
        }
        function onLogChanged(): void {
            if (NotifyPrefs.log === "saved")
                root.commit(true);
            else if (!root.fixed)
                root.removeFile();
        }
    }
    // A monitor that goes away takes its transmissions to the log, unread (edge case).
    Connections {
        target: Quickshell
        function onScreensChanged(): void {
            const names = Quickshell.screens.map(sc => sc.name);
            let changed = false;
            for (const t of root.stack.filter(x => !names.includes(x.monitor))) {
                t.entry.read = false;
                changed = true;
            }
            if (changed)
                root.stack = root.stack.filter(x => names.includes(x.monitor));
            if (root.critical && !names.includes(root.critical.monitor))
                root.critical = { ids: root.critical.ids, page: root.critical.page, monitor: root.monitorFor() };
            if (changed)
                root.commit(false);
        }
    }

    // --- fixtures -----------------------------------------------------------------------------------------
    function loadFixture(): void {
        const f = fixture ?? {};
        const at = text => {
            const d = Clock.parseLocal(text);
            return d ? d.getTime() : 0;
        };
        const list = (Array.isArray(f.log) ? f.log : []).map((x, i) => makeEntry(Number.isInteger(x.id) ? x.id : -(i + 1), {
            app: String(x.app ?? ""),
            appKey: String(x.app ?? ""),
            system: x.system === true,
            title: NotifyText.plain(x.title ?? ""),
            body: NotifyText.sanitize(x.body ?? ""),
            urgency: ["low", "normal", "critical"].includes(x.urgency) ? x.urgency : "normal",
            actions: Array.isArray(x.actions) ? x.actions.map(a => ({ id: String(a.id), label: String(a.label) })) : [],
            hasDefault: x.hasDefault === true,
            defaultLabel: x.hasDefault === true && Array.isArray(x.actions) && x.actions.length > 0 ? String(x.actions[0].label) : "",
            reply: typeof x.reply === "string" ? { label: x.reply } : null,
            image: x.image ? "file://" + Fixtures.resolve(String(x.image)) : "",
            progress: Number.isInteger(x.progress) ? x.progress : null,
            read: x.read === true,
            alive: x.alive !== false,
            count: Number.isInteger(x.count) ? x.count : 1
        }, at(x.at)));
        entries = list;
        const shownAt = Clock.date.getTime();
        stack = (Array.isArray(f.screen) ? f.screen : []).filter(id => list.some(e => e.id === id)).map(id => {
            const e = list.find(x => x.id === id);
            return {
                key: "f" + id, id: id, ids: [id], entry: e, appKey: e.appKey, count: e.count ?? 1, monitor: monitorFor(),
                arrivedAt: shownAt, shownAt: shownAt, typedAt: shownAt, typed: true, from: 0,
                expiresAt: null, remaining: null, total: null, paused: false, hover: false, replying: false
            };
        });
        const crit = (Array.isArray(f.critical) ? f.critical : []).filter(id => list.some(e => e.id === id));
        critical = crit.length > 0 ? { ids: crit, page: 0, monitor: monitorFor() } : null;
        overflow = Number.isInteger(f.overflow) ? f.overflow : 0;
        trimLog();
        clock.stop();
        commit(false);
    }
    function resetLive(): void {
        entries = [];
        stack = [];
        critical = null;
        overflow = 0;
        clock.stop();
        restoreSession();
    }
    Connections {
        target: Fixtures
        function onDataChanged(): void {
            if (root.fixed)
                root.loadFixture();
            else
                root.resetLive();
        }
    }

    // --- the session across reloads (R15) -------------------------------------------------------------------
    PersistentProperties {
        id: session
        reloadableId: "notify-session"
        property string json: ""
        property bool started: false
        property int seq: 0
        onLoaded: root.sessionReady()
    }
    property bool ready: false
    function sessionReady(): void {
        if (ready)
            return;
        ready = true;
        systemSeq = session.seq;
        if (fixed) {
            loadFixture();
            return;
        }
        if (!restoreSession() && !session.started && saving)
            fileView.reload();                   // a new session: the saved log comes back (FR-019)
        session.started = true;
    }
    function restoreSession(): bool {
        if (!session.json)
            return false;
        try {
            const list = JSON.parse(session.json);
            if (Array.isArray(list)) {
                // What was alive comes back with the server's re-emission (lastGeneration).
                entries = list.map(e => Object.assign(e, { alive: e.alive && live[e.id] !== undefined, isNew: false }));
                commit(false);
                return true;
            }
        } catch (err) {
        }
        return false;
    }
    function saveSession(): void {
        if (fixed)
            return;
        session.json = JSON.stringify(entries);
        session.seq = systemSeq;
    }

    // --- the saved log (Text log: Saved, FR-019, R14) -------------------------------------------------------
    function savedEntries(): var {
        return entries.filter(e => !e.transient).slice(0, NotifyPrefs.logSize).map(e => {
            const out = { app: e.app, system: e.system, title: e.title, body: e.body, urgency: e.urgency, at: Math.round(e.at), read: true };
            if (typeof e.image === "string" && e.image.startsWith("file://"))
                out.image = e.image;
            if (e.progress !== null)
                out.progress = e.progress;
            return out;
        });
    }
    Timer {
        id: saveTimer
        interval: Tokens.notify.saveMs
        onTriggered: root.writeFile()
    }
    property bool fileReady: false
    function writeFile(): void {
        if (!saving)
            return;
        if (!fileReady) {
            // The file is created 600 first; the atomic write keeps the mode (spike T004, item 7).
            fileCreate.command = ["sh", "-c", "[ -e \"$1\" ] || install -D -m 600 /dev/null \"$1\"", "sh", statePath];
            fileCreate.running = true;
            return;
        }
        fileView.setText(JSON.stringify({ version: 1, entries: savedEntries() }) + "\n");
    }
    Process {
        id: fileCreate
        onExited: (code, status) => {
            root.fileReady = code === 0;
            if (root.fileReady)
                root.writeFile();
            else
                console.info(`notifications: cannot create ${root.statePath} (exit ${code})`);
        }
    }
    function removeFile(): void {
        fileReady = false;
        saveTimer.stop();
        fileRemove.command = ["rm", "-f", "--", statePath];
        fileRemove.running = true;
    }
    Process {
        id: fileRemove
    }
    function loadFile(text: string): void {
        if (!text)
            return;
        let ok = false;
        let list = [];
        try {
            const d = JSON.parse(text);
            ok = d && d.version === 1 && Array.isArray(d.entries)
                && d.entries.every(x => x && typeof x.title === "string" && typeof x.at === "number");
            list = ok ? d.entries : [];
        } catch (err) {
            ok = false;
        }
        if (!ok) {
            const bak = statePath + ".bak-" + Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss");
            console.info(`notifications: ${statePath} is not a saved log this version reads, moved to ${bak}; the log starts empty`);
            fileBackup.command = ["mv", "-f", "--", statePath, bak];
            fileBackup.running = true;
            return;
        }
        fileReady = true;
        const old = list.slice(0, NotifyPrefs.logSize).map((x, i) => makeEntry(-1 - i - 2000000, {
            app: String(x.app ?? ""), appKey: String(x.app ?? ""), system: x.system === true,
            title: String(x.title), body: NotifyText.sanitize(x.body ?? ""),
            urgency: ["low", "normal", "critical"].includes(x.urgency) ? x.urgency : "normal",
            image: typeof x.image === "string" && x.image.startsWith("file://") ? x.image : "",
            progress: Number.isInteger(x.progress) ? x.progress : null,
            read: true, alive: false, earlier: true
        }, x.at));
        entries = entries.concat(old);
        trimLog();
        commit(false);
    }
    Process {
        id: fileBackup
    }
    FileView {
        id: fileView
        path: root.statePath
        atomicWrites: true
        printErrors: false
        blockLoading: false
        preload: false
        onLoaded: root.loadFile(text())
    }

    // --- the injector (FR-032, R17): the mockup's samples through the real path of an app -------------
    function gv(s: string): string {
        return "'" + s.replace(/\\/g, "\\\\").replace(/'/g, "\\'") + "'";
    }
    function sample(name: string): string {
        const S = Strings.notify.samples;
        const ns = (args) => Quickshell.execDetached(["notify-send"].concat(args));
        switch (name) {
        case "normal":
            ns(["-a", S.normal.app, S.normal.title, S.normal.body]);
            break;
        case "actions":
            ns(["-a", S.actions.app].concat(S.actions.actions.map(a => `--action=${a[0]}=${a[1]}`)).concat([S.actions.title, S.actions.body]));
            break;
        case "reply":
            Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                "--object-path", "/org/freedesktop/Notifications", "--method", "org.freedesktop.Notifications.Notify",
                gv(S.reply.app), "0", "''", gv(S.reply.title), gv(S.reply.body), "['inline-reply', 'Reply']",
                `{'image-path': <${gv(Quickshell.shellPath("fixtures/notify/avatar.png"))}>}`, "0"]);
            break;
        case "critical":
            ns(["-u", "critical", "-a", S.critical.app, S.critical.title, S.critical.body]);
            break;
        case "flood5":
            for (let i = 1; i <= 5; i++)
                ns(["-a", S.flood.app, S.flood.title, S.flood.body.arg(i)]);
            break;
        case "long":
            ns(["-a", S.long.app, S.long.title, S.long.body]);
            break;
        case "progress":
            ns(["-a", S.progress.app, "-h", `int:value:${S.progress.value}`, S.progress.title, S.progress.body]);
            break;
        case "low":
            ns(["-u", "low", "-a", S.low.app, S.low.title, S.low.body]);
            break;
        case "script100":
            for (let i = 1; i <= 100; i++)
                ns(["-u", "low", "-a", S.script.app, S.script.title.arg(i), S.script.body.arg(i)]);
            break;
        case "system":
            system(S.system.title, S.system.body, "normal", false);
            break;
        default:
            return "error: samples are normal, actions, reply, critical, flood5, long, progress, low, script100, system";
        }
        return "ok";
    }

    // --- dump (contracts/ipc.md) ----------------------------------------------------------------------------
    function dumpState(): var {
        refreshOwner();
        return {
            server: server,
            serverOwner: fixed ? "qs" : serverOwner,
            held: held,
            fullscreen: Compositor.focusedFullscreen,
            prefs: NotifyPrefs.dump(),
            unread: unread,
            overflow: overflow,
            screen: stack.map(t => {
                const e = t.entry ?? {};
                return {
                    id: t.id, monitor: t.monitor, speaker: speakerOf(e), title: e.title ?? "", body: NotifyText.plain(e.body ?? ""),
                    urgency: e.urgency ?? "normal", count: t.count, typed: t.typed, shown: shownOf(t),
                    remaining: remainingOf(t.id), paused: t.paused, replying: t.replying,
                    actions: (e.actions ?? []).slice(0, Tokens.notify.maxActions).map(a => a.label),
                    reply: e.reply !== null && e.reply !== undefined, image: (e.image ?? "") !== "",
                    progress: e.progress ?? null, arrivedAt: Math.round(t.arrivedAt), shownAt: Math.round(t.shownAt),
                    typedAt: Math.round(t.typedAt), box: null
                };
            }),
            critical: critical ? { monitor: critical.monitor, ids: critical.ids, page: critical.page + 1, box: null } : null,
            log: { count: entries.length, limit: NotifyPrefs.logSize, saved: saving, file: saving ? statePath : "", ids: entries.map(e => e.id) },
            entries: entries.slice(0, 20).map(e => ({
                id: e.id, speaker: speakerOf(e), title: e.title, urgency: e.urgency, read: e.read, isNew: e.isNew,
                alive: e.alive, earlier: e.earlier, answered: e.answered, image: e.image !== "", progress: e.progress
            }))
        };
    }

    Component.onCompleted: {
        // PersistentProperties emits loaded() after the first frame of a reload; on a fresh start too.
        Qt.callLater(() => {
            if (!root.ready && session.json === "")
                root.sessionReady();
        });
    }
}
