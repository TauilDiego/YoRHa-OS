pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../ds"
import "../../ds/primitives"
import "../../ds/base"
import "../../ds/composites"
import "../../hud"
import "../../strings"

// The gallery's page 4 (spec 008, FR-034): the band and its pieces, from fixed samples (the mockup's
// texts), nothing animating: the band over paper and over the dark scene, transmissions (still at
// half their typing, with actions, with an image and the reply field open, low with progress,
// grouped ×5), the critical band with 1/2, the action button and the tags, the OSD in its four kinds,
// the stack in its three positions and the bar's counter in both tones.
Rectangle {
    id: root

    property real s: 1
    property real dpr: 1

    readonly property var G: Strings.gallery
    readonly property var S: Strings.notify.samples
    readonly property real at: new Date(2026, 9, 26, 13, 37).getTime()
    readonly property string avatar: "file://" + Quickshell.shellPath("fixtures/notify/avatar.png")

    function u(v: real): int {
        return Tokens.px(v, s);
    }
    function sample(id: int, f: var): var {
        return Object.assign({ id: id, app: "", system: false, title: "", body: "", urgency: "normal", actions: [],
                               hasDefault: false, reply: null, image: "", progress: null, at: root.at, alive: true,
                               earlier: false, answered: "" }, f);
    }
    readonly property var normal: sample(1, { app: S.normal.app, title: S.normal.title, body: S.normal.body })
    readonly property var actions: sample(2, { app: S.actions.app, title: S.actions.title, body: S.actions.body,
                                               actions: S.actions.actions.map(a => ({ id: a[0], label: a[1] })) })
    readonly property var reply: sample(3, { app: S.reply.app, title: S.reply.title, body: S.reply.body,
                                             reply: { label: Strings.notify.reply }, image: root.avatar })
    readonly property var progress: sample(4, { app: S.progress.app, title: S.progress.title, body: S.progress.body,
                                                progress: S.progress.value, urgency: "low" })
    readonly property var flood: sample(5, { app: S.flood.app, title: S.flood.title, body: S.flood.body.arg(5) })
    readonly property var crit1: sample(6, { app: S.critical.app, title: S.critical.title, body: S.critical.body,
                                             urgency: "critical", actions: [{ id: "settings", label: "Power settings" }] })
    readonly property var crit2: sample(7, { app: "Disk", title: "Disk almost full", body: "Only 2 GB left on /home.", urgency: "critical" })

    color: Tokens.color.darkYellow

    PageHeader {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(Tokens.space.pageMarginV)
        s: root.s
        title: root.G.title
        subtitle: root.G.page4Subtitle
    }
    Rule {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(128)
        width: parent.width - 2 * x
        s: root.s
    }

    component Section: Column {
        id: section
        property string name
        spacing: root.u(10)
        Label {
            s: root.s
            role: "small"
            text: section.name
        }
    }
    component Tx: Transmission {
        width: root.u(540)
        s: root.s
        dpr: root.dpr
        instant: true
        showLife: false
    }

    // --- column 1: transmissions -----------------------------------------------------------------
    Column {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(160)
        spacing: root.u(22)

        Section {
            name: root.G.transmission + " · " + root.G.typingHalf
            Transmission {
                id: half
                width: root.u(540)
                s: root.s
                dpr: root.dpr
                entry: root.normal
                speaker: root.normal.app
                lifeFrac: 0.62
                lifeMs: 0
                showLife: false
                Component.onCompleted: half.children[3].children[4].children[0].stillAt = 0.5
            }
        }
        Section {
            name: root.G.withActions
            Tx {
                entry: root.actions
                speaker: root.actions.app
            }
        }
        Section {
            name: root.G.withReply
            Tx {
                entry: root.reply
                speaker: root.reply.app
                replying: true
            }
        }
    }

    // --- column 2: more transmissions, the critical band, the pieces -----------------------------------
    Column {
        x: root.u(Tokens.space.pageMarginH + 618)
        y: root.u(160)
        spacing: root.u(22)

        Section {
            name: root.G.withProgress
            Tx {
                entry: root.progress
                speaker: root.progress.app
            }
        }
        Section {
            name: root.G.grouped
            Tx {
                entry: root.flood
                speaker: root.flood.app
                count: 5
            }
        }
        Section {
            name: root.G.criticalBand + " · 1/2"
            Item {
                width: root.u(540)
                height: critMini.height
                clip: true
                CriticalBand {
                    id: critMini
                    width: root.u(540)
                    height: implicitHeight
                    s: root.s * 540 / 1920 * 1.6
                    dpr: root.dpr
                    instant: true
                    sweepIn: false
                    entries: [root.crit1, root.crit2]
                    speaker: root.crit1.app
                }
            }
        }
        Section {
            name: root.G.actionButton + " · " + root.G.tags
            Rectangle {
                width: root.u(540)
                height: root.u(64)
                color: Tokens.notify.band
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.u(20)
                    spacing: root.u(12)
                    ActionButton { s: root.s; dpr: root.dpr; text: "Open" }
                    ActionButton { s: root.s; dpr: root.dpr; text: "Snooze"; on: true }
                    ActionButton { s: root.s; dpr: root.dpr; text: "Closed"; enabled: false }
                    Tag { anchors.verticalCenter: parent.verticalCenter; s: root.s; dpr: root.dpr; text: Strings.notify.critical }
                    Tag { anchors.verticalCenter: parent.verticalCenter; s: root.s; dpr: root.dpr; text: Strings.notify.newTag; outline: true }
                }
            }
        }
    }

    // --- column 3: the band, the OSD, the positions, the counter -----------------------------------------
    Column {
        x: root.u(Tokens.space.pageMarginH + 2 * 618)
        y: root.u(160)
        spacing: root.u(20)

        Section {
            name: root.G.band + " · " + root.G.overPaper + " / " + root.G.overDark
            Row {
                spacing: root.u(12)
                Band {
                    width: root.u(260)
                    height: root.u(56)
                    s: root.s
                    dpr: root.dpr
                    block: Tokens.color.lightYellow
                    arcs: [[300, 120, 110, 180, 280]]
                }
                Rectangle {
                    width: root.u(270)
                    height: root.u(66)
                    color: "#2a2c33"
                    Band {
                        x: root.u(5)
                        y: root.u(5)
                        width: root.u(256)
                        height: root.u(52)
                        s: root.s
                        dpr: root.dpr
                        block: Tokens.color.mediumGray
                    }
                }
            }
        }
        Section {
            name: root.G.osd
            Column {
                spacing: root.u(10)
                OsdView { s: root.s * 0.9; dpr: root.dpr; label: Strings.notify.volume; value: 66 }
                OsdView { s: root.s * 0.9; dpr: root.dpr; label: Strings.notify.volume; value: 66; muted: true; valueText: Strings.notify.mute }
                OsdView { s: root.s * 0.9; dpr: root.dpr; label: Strings.notify.micOff; meter: false; valueText: "" }
                OsdView { s: root.s * 0.9; dpr: root.dpr; label: Strings.notify.brightness; value: 40 }
            }
        }
        Section {
            name: root.G.positions
            Row {
                spacing: root.u(10)
                Repeater {
                    model: ["corner", "top", "subtitle"]
                    Item {
                        id: tile
                        required property string modelData
                        width: root.u(176)
                        height: root.u(99)
                        clip: true
                        Rectangle {
                            anchors.fill: parent
                            color: Tokens.color.darkYellow
                            border.width: Tokens.line(1, root.s)
                            border.color: Tokens.color.darkGray
                        }
                        TransmissionStack {
                            anchors.fill: parent
                            s: root.s * 176 / 1920
                            dpr: root.dpr
                            instant: true
                            position: tile.modelData
                            topInset: Tokens.px(68 + (tile.modelData === "top" ? 0 : 12), s)
                            items: [
                                { key: "a", id: 1, entry: root.normal, speaker: root.normal.app, count: 1 },
                                { key: "b", id: 2, entry: root.actions, speaker: root.actions.app, count: 1 }
                            ]
                        }
                    }
                }
            }
        }
        Section {
            name: root.G.counter
            Row {
                spacing: root.u(12)
                Rectangle {
                    width: root.u(130)
                    height: root.u(40)
                    color: Tokens.color.darkYellow
                    border.width: Tokens.line(1, root.s)
                    border.color: Tokens.color.lightGray
                    LogCounter { anchors.centerIn: parent; s: root.s; count: 3 }
                }
                Rectangle {
                    width: root.u(130)
                    height: root.u(40)
                    color: "#2a2c33"
                    LogCounter { anchors.centerIn: parent; s: root.s; tone: 1; count: 5; dnd: true }
                }
            }
        }
    }

    Vignette {
        anchors.fill: parent
        s: root.s
        enabled: false
    }
}
