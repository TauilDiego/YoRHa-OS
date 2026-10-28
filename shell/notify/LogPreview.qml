pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../ds/composites"
import "../services"
import "../strings"

// The middle of the text log (spec 008, FR-021, FR-023): a card titled with who speaks, the entry in
// focus on the band, whole (the body typed again whenever the focus lands on it), its actions (dim
// once the app no longer listens), a note (closed, earlier session, answered, or what was just sent)
// and APP / RECEIVED / URGENCY / STATUS. No entry: "No transmissions." The parent sets the size.
Item {
    id: root

    property real s: 1
    property real dpr: 1
    property var entry: null
    property var focusKey: 0                     // a new value types the body again
    property string note: ""                     // a short message after an action (LogPage)
    property bool replying: false

    signal actionClicked(string id)
    signal replyOpened()
    signal replySent(string text)
    signal replyCancelled()

    readonly property var N: Strings.notify
    readonly property bool live: entry !== null && entry.alive && !entry.earlier && entry.answered === ""
    readonly property string status: !entry ? "" : entry.earlier ? N.statusEarlier : entry.answered !== "" ? N.statusAnswered
                                    : !entry.alive ? N.statusClosed : N.statusWaiting
    readonly property string noteText: note !== "" ? note
        : !entry ? "" : entry.earlier ? N.earlierNote
        : entry.answered !== "" ? N.answeredNote.arg(entry.answered === "reply" ? N.reply : (entry.actions.find(a => a.id === entry.answered)?.label ?? entry.answered))
        : !entry.alive ? N.closedNote : ""
    readonly property string speaker: NotifyStore.speakerOf(entry)

    function u(v: real): int {
        return Tokens.px(v, s);
    }
    function focusReply(): void {
        tx.focusReply();
    }

    Card {
        id: card
        anchors.fill: parent
        s: root.s
        mark: true
        title: root.entry ? root.speaker : root.N.transmission

        Column {
            width: parent.width
            spacing: root.u(16)

            Label {
                visible: !root.entry
                width: parent.width
                s: root.s
                role: "standard"
                font.weight: Font.Medium
                font.variableAxes: ({ "wght": Font.Medium })
                wrapMode: Text.Wrap
                text: root.N.emptyText
                color: Tokens.color.mediumGray
            }

            Transmission {
                id: tx
                visible: root.entry !== null
                width: parent.width
                s: root.s
                dpr: root.dpr
                layout: "preview"
                entry: root.entry ?? ({})
                speaker: root.speaker
                instant: Tokens.instant || NotifyStore.fixed
                typeMs: Math.min(Tokens.notify.typeMaxMs, Math.round(NotifyText.visibleLength(root.entry?.body ?? "") / Tokens.notify.cps * 1000))
                typeKey: root.focusKey
                live: root.live
                replying: root.replying
                onActionClicked: id => root.actionClicked(id)
                onReplyOpened: root.replyOpened()
                onReplySent: text => root.replySent(text)
                onReplyCancelled: root.replyCancelled()
            }

            Grid {
                id: info
                visible: root.entry !== null
                width: parent.width
                columns: 2
                rowSpacing: root.u(10)
                columnSpacing: root.u(18)
                readonly property var rows: root.entry ? [
                    [root.N.app, root.entry.app || (root.entry.system ? root.speaker : root.N.unknown)],
                    [root.N.received, Qt.formatDateTime(new Date(Number(root.entry.at)), root.N.dateFormat)],
                    [root.N.urgency, root.N.urgencyLabels[root.entry.urgency] ?? ""],
                    [root.N.status, root.status]
                ] : []
                Repeater {
                    model: info.rows.reduce((cells, r) => cells.concat([{ t: r[0], v: false }, { t: r[1], v: true }]), [])
                    Label {
                        required property var modelData
                        width: modelData.v ? info.width - info.columnSpacing - labelMeasure.implicitWidth : implicitWidth
                        s: root.s
                        role: "small"
                        upper: !modelData.v
                        font.pixelSize: modelData.v ? Tokens.px(18, root.s) : Tokens.px(16, root.s)
                        font.weight: modelData.v ? Font.DemiBold : Font.Medium
                        font.variableAxes: ({ "wght": modelData.v ? Font.DemiBold : Font.Medium })
                        horizontalAlignment: modelData.v ? Text.AlignRight : Text.AlignLeft
                        elide: Text.ElideRight
                        text: modelData.t
                        color: modelData.v ? Tokens.color.darkGray : Tokens.color.mediumGray
                    }
                }
            }
            Label {
                id: labelMeasure
                visible: false
                s: root.s
                role: "small"
                upper: true
                font.pixelSize: Tokens.px(16, root.s)
                text: root.N.received
            }

            Label {
                visible: root.noteText !== ""
                width: parent.width
                s: root.s
                role: "small"
                font.weight: Font.DemiBold
                font.variableAxes: ({ "wght": Font.DemiBold })
                font.letterSpacing: root.s
                wrapMode: Text.Wrap
                text: root.noteText
                color: root.note !== "" ? Tokens.color.darkGray : Tokens.color.mediumGray
            }
        }
    }
}
