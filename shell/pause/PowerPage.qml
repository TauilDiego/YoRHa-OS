pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../ds/composites"
import "../services"
import "../strings"

// The pause menu's POWER (spec 007, US4, frente C): session and power actions, in the columns of
// the PickerLayout (list at x 48, middle card at 560, right card at 1160):
//   list    a GroupedList without groups: Lock, Log out, Suspend, Hibernate, Reboot, Shut down; the
//           ones the machine can't do are dimmed (they take the cursor, Enter does nothing);
//   middle  a DescriptionCard: the action, what it does, what happens now (`effect`, with the
//           number of windows), whether it asks first, and in alert the reason it is off or the
//           system's refusal;
//   right   the StatusCard: USER, HOST, UPTIME, BATTERY (with its meter), WINDOWS.
// Enter (or a click) on an action: dimmed → nothing; one that confirms (Session.actions[].confirm,
// from SYSTEM › Pause menu › Confirm) → the ConfirmDialog, its kite where `Dialog starts on` says;
// otherwise it runs. Order (FR-023): lock, suspend and hibernate close the menu, then run; log out,
// reboot and shut down run, and the menu closes once the system accepts. A refusal keeps the menu
// open with the error on the card. The dialog is cancelled whenever the menu loses the keyboard
// (closed, or another tab). Entering the tab re-reads the machine (Session.refresh()); the uptime
// is read again every minute while the tab is shown.
FocusScope {
    id: root

    property real s: 1
    property real startY: Tokens.space.pauseBodyY
    property bool active: false              // the tab is open and the menu has the keyboard
    readonly property string confirmMode: Session.confirmMode
    readonly property string dialogStart: SettingsModel.choiceId("menu", "confirm-start") || "cancel"

    signal closeRequested()

    property int index: 0
    property string dialogAction: ""         // the action the dialog asks about ("" = closed)
    property string waiting: ""              // a closing action run from here, until it answers

    readonly property var actions: Session.actions
    readonly property var current: actions[index] ?? null
    readonly property var dialogData: dialogAction !== "" ? Session.actionOf(dialogAction) : null

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    // 8040 s → "2h 14m"; under an hour "14m"; from a day on "1d 3h".
    function uptimeText(sec: int): string {
        const P = Strings.pause;
        const m = Math.floor(sec / 60) % 60, h = Math.floor(sec / 3600), d = Math.floor(sec / 86400);
        if (d > 0)
            return P.uptimeD.arg(d).arg(h % 24);
        if (h > 0)
            return P.uptimeHM.arg(h).arg(m);
        return P.uptimeM.arg(m);
    }

    function batteryText(b: var): string {
        if (!b)
            return Strings.pause.noBattery;
        return (b.charging ? Strings.pause.charging : Strings.pause.percent).arg(b.percent);
    }

    readonly property var status: Session.status
    readonly property string footerLeft: Strings.pause.powerFooter.arg(uptimeText(status.uptime))

    // --- the footer ------------------------------------------------------------------------------
    readonly property var keys: {
        const K = Strings.settings;
        const out = [{ key: K.keyUpDown, label: K.select }];
        if (current && current.available)
            out.push({ key: K.keyEnter, label: current.label });
        out.push({ key: K.keyEsc, label: K.close });
        return out;
    }

    // --- what the middle card says ----------------------------------------------------------------
    readonly property var card: {
        const a = current, P = Strings.pause;
        if (!a)
            return { title: "", text: "", effect: "", note: "", kind: "alert", meta: [] };
        let note = "", kind = "alert";
        if (Session.error !== "")
            note = Session.error;
        else if (Session.lastError !== "")
            note = Session.lastError;
        else if (Session.busy === a.id) {
            note = P.running;
            kind = "info";
        } else if (!a.available)
            note = a.reason;
        return {
            title: a.label,
            text: P.powerTexts[a.id] ?? "",
            effect: a.effect,
            note: note,
            kind: kind,
            meta: [
                { label: P.now, value: a.available ? a.effect : P.unavailable },
                { label: P.confirmation, value: a.confirm ? P.asked : P.noneAsked }
            ]
        };
    }

    // --- actions -----------------------------------------------------------------------------------
    function trigger(i: int): void {
        const a = actions[i];
        if (!a || !a.available || Session.busy !== "" || dialogAction !== "")
            return;
        index = i;
        if (a.confirm)
            openDialog(a.id);
        else
            execute(a.id);
    }

    function execute(id: string): void {
        if (Session.closesSession(id)) {
            waiting = id;
            Session.run(id);              // the menu closes on accepted (below)
        } else {
            closeRequested();             // a clean screen first (FR-023)
            Session.run(id);
        }
    }

    function openDialog(id: string): void {
        Session.refresh();
        dialogAction = id;
        dialog.reset();
        dialog.forceActiveFocus();
    }

    function closeDialog(): void {
        if (dialogAction === "")
            return;
        dialogAction = "";
        listKeys.forceActiveFocus();
    }

    Connections {
        target: Session
        function onAccepted(id: string): void {
            if (id === root.waiting) {
                root.waiting = "";
                root.closeRequested();
            }
        }
        function onRefused(id: string, reason: string): void {
            if (id === root.waiting)
                root.waiting = "";
        }
    }

    // --- the menu's calls ---------------------------------------------------------------------------
    function restart(): void {
        closeDialog();
        index = 0;                       // POWER opens on Lock (FR-006)
        waiting = "";
    }
    function enter(): void {
        Session.refresh();
    }
    function leave(): void {
        closeDialog();
    }

    onActiveChanged: {
        if (!active)
            closeDialog();
    }

    function rectOf(item: Item): var {
        if (!item)
            return null;
        const p = item.mapToItem(null, 0, 0);
        return { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(item.width), h: Math.round(item.height) };
    }

    function geometry(): var {
        if (dialogAction !== "")
            return { item: dialog.geometry().item, value: null };
        return { item: rectOf(list.itemAt(index)), value: null };
    }

    function dumpState(): var {
        const st = status;
        const d = dialogData;
        return {
            column: "list",
            item: current?.id ?? "",
            dimmed: actions.filter(a => !a.available).map(a => a.id),
            busy: Session.busy,
            card: { title: card.title, effect: card.effect, note: card.note },
            status: {
                user: st.user,
                host: st.host,
                uptime: uptimeText(st.uptime),
                battery: st.battery ? batteryText(st.battery) : null,
                windows: st.windows,
                note: st.note === "" ? Strings.pause.noError : st.note
            },
            dialog: d ? {
                action: d.id,
                row: dialog.row,
                title: dialog.title,
                text: dialog.text,
                blockers: dialog.blockerLines,
                keys: dialog.keys.map(k => `${k.key} ${k.label}`),
                geometry: dialog.geometry()
            } : null,
            error: Session.error
        };
    }

    // --- keys ----------------------------------------------------------------------------------------
    Item {
        id: listKeys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const k = event.key, n = root.actions.length;
            event.accepted = true;
            if (k === Qt.Key_Up && n > 0)
                root.index = (root.index - 1 + n) % n;
            else if (k === Qt.Key_Down && n > 0)
                root.index = (root.index + 1) % n;
            else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                root.trigger(root.index);
            else if (k === Qt.Key_Escape)
                root.closeRequested();
            else if (k !== Qt.Key_Left && k !== Qt.Key_Right)
                event.accepted = false;
        }
    }

    // The uptime, again every minute while POWER is shown (live data only).
    Timer {
        interval: 60000
        repeat: true
        running: root.active && !Session.fixed
        onTriggered: Session.readStatus()
    }

    // --- the pointer: hover moves the cursor only when the pointer really moved --------------------
    property bool pointerMoved: false
    HoverHandler {
        id: pointer
        property point last: Qt.point(NaN, NaN)
        onPointChanged: {
            const p = point.scenePosition;
            if (p.x === last.x && p.y === last.y)
                return;
            const first = isNaN(last.x);
            last = p;
            if (!first)
                root.pointerMoved = true;
        }
    }

    // --- layout --------------------------------------------------------------------------------------
    readonly property int topY: u(startY)
    readonly property int bottomY: height - u(Tokens.space.popupH - 820) - u(24)

    GroupedList {
        id: list
        x: root.u(48)
        y: root.topY
        width: implicitWidth
        height: Math.min(implicitHeight, root.bottomY - y)
        s: root.s
        model: root.actions.map(a => ({ label: a.label, dim: !a.available }))
        currentIndex: root.index
        focused: root.dialogAction === ""
        keysEnabled: false
        onHoveredIndex: i => {
            if (root.pointerMoved && root.dialogAction === "")
                root.index = i;
        }
        onActivated: i => root.trigger(i)
    }

    DescriptionCard {
        id: description
        x: root.u(560)
        y: root.topY
        width: root.u(Tokens.space.pickerPreviewW)
        s: root.s
        minHeight: root.u(360)
        maxHeight: root.bottomY - y
        title: root.card.title
        text: root.card.text
        note: root.card.note
        noteKind: root.card.kind
        meta: root.card.meta
    }

    StatusCard {
        id: statusCard
        x: root.u(1160)
        y: root.topY
        width: root.u(Tokens.space.pickerOptionsW)
        s: root.s
        rows: [
            { label: Strings.pause.user, value: root.status.user, meter: null },
            { label: Strings.pause.host, value: root.status.host, meter: null },
            { label: Strings.pause.uptime, value: root.uptimeText(root.status.uptime), meter: null },
            { label: Strings.pause.battery, value: root.batteryText(root.status.battery),
              meter: root.status.battery ? root.status.battery.percent / 100 : null },
            { label: Strings.pause.windowsCount, value: String(root.status.windows), meter: null }
        ]
        note: root.status.note
    }

    ConfirmDialog {
        id: dialog
        anchors.fill: parent
        visible: root.dialogAction !== ""
        enabled: visible
        s: root.s
        start: root.dialogStart
        title: root.dialogData ? Strings.pause.dialogTitle.arg(root.dialogData.label) : ""
        text: root.dialogData
            ? (Session.closesSession(root.dialogData.id)
                ? `${root.dialogData.effect} ${Strings.pause.unsavedMayAsk}` : root.dialogData.effect)
            : ""
        note: root.dialogData && root.dialogData.id === root.current?.id && Session.lastError !== "" ? Session.lastError : ""
        blockers: root.dialogData?.blockers ?? []
        actionLabel: root.dialogData?.label ?? ""
        onConfirmed: {
            const id = root.dialogAction;
            root.closeDialog();
            root.execute(id);
        }
        onCancelled: root.closeDialog()
    }
}
