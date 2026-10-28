pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../ds"
import "../ds/composites"
import "../services"
import "../strings"

// The text log's body (spec 008 US4, FR-020–FR-024, FR-044; contracts/components.md): one piece that
// any host frames. Now in its own pop-up (LogPopup, host "popup"); later as the 5th tab of the pause
// menu (spec 007, host "pause"). It has no window and no title or footer of its own: it exposes
// `title`, `subtitle`, `footerLeft` and `keys` for the host to draw, and fits whatever rect it gets
// (PickerLayout { fluid: true }):
//   left    the transmissions, newest first, grouped in NOW (the last hour) and EARLIER, each row
//           with who speaks, the title, the time, ×N and NEW; filtered by Show;
//   middle  the entry in focus, whole, typed again when it gets the focus (LogPreview);
//   right   Options: Do not disturb (the same NotifyPrefs.dnd), Show (All, Unread, Critical), Clear all;
//           then UNREAD, KEPT and SERVER.
// Keys (two columns, as the 003/004): list ↑↓, Enter the default action, Delete dismisses (the focus
// goes to the next), → options, Esc closes; options ↑↓, ←→ change, Enter, Esc back.
// The host sets NotifyStore.logOpen while it shows (opening marks everything read, FR-024).
//   For the pause menu (007): LogPage { host: "pause"; s; width; height } in the tab's body; read
//   title/subtitle/footerLeft/keys; set NotifyStore.logOpen = true while the tab shows.
FocusScope {
    id: root

    property real s: 1
    property real dpr: 1
    property string host: "popup"                // "popup" | "pause"
    property bool active: true
    property string monitor: ""

    signal closeRequested()

    readonly property var N: Strings.notify
    readonly property string title: N.title
    readonly property string subtitle: N.subtitle
    readonly property string footerLeft: N.footer

    property int filter: 0                       // 0 All, 1 Unread (NEW), 2 Critical
    readonly property var filters: ["all", "unread", "critical"]
    readonly property var shown: NotifyStore.entries.filter(e => filter === 0 || (filter === 1 ? e.isNew : e.urgency === "critical"))
    readonly property int index: layout.index
    readonly property var entry: shown[Math.max(0, Math.min(index, shown.length - 1))] ?? null
    property int focusSeq: 0
    property string note: ""
    property bool replying: false

    function u(v: real): int {
        return Tokens.px(v, s);
    }

    // NOW = the last hour (of the fixture's clock, with fixtures).
    readonly property real nowMs: Clock.date.getTime()
    function timeOf(e: var): string {
        return Qt.formatDateTime(new Date(Number(e.at)), N.timeFormat);
    }
    readonly property var rows: {
        const out = [];
        if (shown.length === 0)
            return [{ note: N.emptyTitle }];
        let grp = "";
        for (const e of shown) {
            const g = nowMs - Number(e.at) <= 3600000 ? N.now : N.earlier;
            if (g !== grp) {
                grp = g;
                out.push({ group: g });
            }
            out.push({
                label: e.title,
                lead: NotifyStore.speakerOf(e),
                trailing: timeOf(e),
                tag: e.isNew ? N.newTag : "",
                markColor: e.urgency === "critical" ? Tokens.color.alert : "transparent"
            });
        }
        return out;
    }

    readonly property var options: [
        { id: "dnd", label: N.dnd, type: "toggle" },
        { id: "show", label: N.show, values: [N.showAll, N.showUnread, N.showCritical] },
        { id: "clear", label: N.clearAll, type: "action", text: N.clear }
    ]
    readonly property var values: ({ dnd: NotifyPrefs.dnd, show: filter })
    readonly property var info: [
        { label: N.unread, value: String(NotifyStore.entries.filter(e => e.isNew).length) },
        { label: N.kept, value: N.keptOf.arg(NotifyStore.entries.length).arg(NotifyPrefs.logSize) },
        { label: N.server, value: NotifyStore.server ? N.serverOn : N.serverOff }
    ]

    // The default action of the entry in focus, when its app still listens.
    readonly property bool canAct: entry !== null && entry.alive && !entry.earlier && entry.answered === "" && entry.hasDefault === true

    readonly property var keys: {
        const S = Strings.settings;
        if (layout.column === "options")
            return layout.keys;
        const out = [{ key: S.keyUpDown, label: N.keySelect }];
        if (canAct)
            out.push({ key: S.keyEnter, label: entry.defaultLabel || N.keyAction });
        if (entry)
            out.push({ key: N.keyDelete, label: N.keyDismiss });
        out.push({ key: S.keyRight, label: N.keyOptions }, { key: S.keyEsc, label: N.keyClose });
        return out;
    }

    function restart(): void {
        filter = 0;
        note = "";
        replying = false;
        layout.restart(0);
        focusSeq++;
        layout.forceActiveFocus();
    }
    function flash(text: string): void {
        note = text;
        noteTimer.restart();
    }
    Timer {
        id: noteTimer
        interval: Tokens.motion.actionBusy
        onTriggered: root.note = ""
    }
    onIndexChanged: {
        focusSeq++;
        note = "";
        replying = false;
    }

    function act(actionId: string): void {
        const e = entry;
        if (!e)
            return;
        const label = actionId === "default" ? (e.defaultLabel || N.keyAction) : (e.actions.find(a => a.id === actionId)?.label ?? actionId);
        if (NotifyStore.invoke(e.id, actionId) === "ok")
            flash(N.answeredNote.arg(label));
    }

    Keys.onPressed: event => {
        if (layout.column === "list" && event.key === Qt.Key_Delete && entry) {
            const i = layout.index;
            NotifyStore.dismiss(entry.id);
            layout.index = Math.max(0, Math.min(i, shown.length - 1));
            focusSeq++;
            event.accepted = true;
        }
    }

    PickerLayout {
        id: layout
        x: 0
        y: root.host === "popup" ? root.u(150) : 0
        width: root.width
        height: root.host === "popup" ? root.height - y - root.u(Tokens.space.popupH - 820) - root.u(24) : root.height
        s: root.s
        fluid: true
        focus: true
        entries: root.rows
        options: root.options
        values: root.values
        info: root.info
        optionsTitle: root.N.options
        onApplied: i => {
            if (root.canAct)
                root.act("default");
        }
        onPicked: (o, v) => {
            const id = root.options[o]?.id;
            if (id === "dnd")
                NotifyPrefs.setDnd(v === true);
            else if (id === "show") {
                root.filter = v;
                layout.index = 0;
            }
        }
        onInvoked: o => {
            if (root.options[o]?.id === "clear") {
                NotifyStore.clear();
                layout.column = "list";
                layout.index = 0;
            }
        }
        onCloseRequested: root.closeRequested()

        LogPreview {
            id: preview
            width: layout.previewWidth
            height: layout.height
            s: root.s
            dpr: root.dpr
            entry: root.entry
            focusKey: root.focusSeq
            note: root.note
            replying: root.replying
            onActionClicked: id => root.act(id)
            onReplyOpened: {
                root.replying = true;
                Qt.callLater(preview.focusReply);
            }
            onReplySent: text => {
                if (root.entry && NotifyStore.reply(root.entry.id, text) === "ok")
                    root.flash(root.N.answeredNote.arg(root.N.reply));
                root.replying = false;
                layout.forceActiveFocus();
            }
            onReplyCancelled: {
                root.replying = false;
                layout.forceActiveFocus();
            }
        }
    }

    // For `notify dump` (contracts/ipc.md, "page").
    function dumpState(): var {
        const geo = layout.geometry();
        return {
            host: host,
            monitor: monitor,
            focus: layout.column,
            index: layout.index,
            option: layout.column === "options" ? layout.option : null,
            filter: filters[filter],
            entry: entry?.id ?? null,
            keys: keys.map(k => `${k.key} ${k.label}`),
            preview: { speaker: entry ? preview.speaker : "", status: preview.status, note: preview.noteText },
            rows: rows.map(r => r.group ?? r.note ?? `■ ${r.lead} · ${r.label} · ${r.trailing}${r.tag ? " " + r.tag : ""}`),
            values: { dnd: NotifyPrefs.dnd, show: [N.showAll, N.showUnread, N.showCritical][filter] },
            geometry: geo
        };
    }
}
