pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"
import "../TextCut.js" as TextCut
import "../../strings"

// The critical band (spec 008, FR-011): a critical notification across the whole monitor, right under
// the bar, like the game's tutorial band. The `alert` block on the left, thin arcs, the text in a
// column (who speaks, CRITICAL, the time; the title; up to 3 typed lines; the actions) and, on the
// right, the page (◂ 1/N ▸, with more than one) and the ×. It stays until dismissed or answered.
//   entries: the Entry objects on the band, newest first; page: the one shown (0-based).
// The parent sets the width; the height follows the text, never under Tokens.notify.critMinH.
Item {
    id: root

    property real s: 1
    property real dpr: 1
    property var entries: []
    property int page: 0
    property bool instant: false
    property string speaker
    property bool sweepIn: true                   // the band sweeps in from the left when it appears

    signal pageStepped(int dir)
    signal closeClicked(int id)
    signal actionClicked(int id, string action)
    signal replyOpened(int id)

    readonly property var N: Tokens.notify
    readonly property var entry: entries[Math.max(0, Math.min(page, entries.length - 1))] ?? null
    readonly property var actions: (Array.isArray(entry?.actions) ? entry.actions : []).slice(0, N.maxActions)

    function u(v: real): int {
        return Tokens.px(v, s);
    }

    implicitHeight: Math.max(u(N.critMinH), u(N.critPadTop) + column.height + u(N.critPadBottom))

    Item {
        id: reveal
        width: root.width
        height: root.height
        clip: sweep.running

        Band {
            width: root.width
            height: root.height
            s: root.s
            dpr: root.dpr
            shadow: false
            block: Tokens.color.alert
            arcs: [[-120, 140, 400, 300, 380], [-120, 140, 407, 300, 380], [2060, 380, 330, 190, 260], [1700, -500, 640, 70, 110]]
        }
        // Its shadow: under the band only (box-shadow 0 3px).
        Rectangle {
            y: root.height
            width: root.width
            height: root.u(root.N.shadow)
            color: Tokens.notify.bandShadow
        }

        Column {
            id: column
            x: root.u(root.N.topPad)
            y: root.u(root.N.critPadTop)
            width: Math.min(root.u(root.N.critCol), root.width - x - root.u(root.N.critSide) - side.width - root.u(24))

            Row {
                spacing: root.u(10)
                Square {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    size: root.N.critWhoSq
                    color: Tokens.notify.bandText
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    role: "critWho"
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, column.width * 0.6)
                    text: root.speaker
                    color: Tokens.notify.bandText
                }
                Tag {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    dpr: root.dpr
                    text: Strings.notify.critical
                }
                Item {
                    width: root.u(8)
                    height: 1
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    role: "bandTime"
                    font.pixelSize: Tokens.px(18, root.s)
                    font.features: ({ "tnum": 1 })
                    text: Qt.formatDateTime(new Date(Number(root.entry?.at ?? 0)), Strings.notify.timeFormat)
                    color: Tokens.notify.bandText2
                }
            }
            Item {
                width: 1
                height: root.u(14)
            }
            Label {
                width: parent.width
                s: root.s
                role: "critTitle"
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                text: String(root.entry?.title ?? "")
                color: Tokens.notify.bandText
            }
            Item {
                width: 1
                height: body.visible ? root.u(root.N.bodyGap) : 0
            }
            TypedText {
                id: body
                width: parent.width
                visible: text !== ""
                s: root.s
                role: "critBody"
                maxLines: root.N.critLines
                text: String(root.entry?.body ?? "")
                instant: root.instant
                ms: Math.min(root.N.typeMaxMs, Math.round(TextCut.visibleLength(text) / root.N.cps * 1000))
                restartKey: root.entry?.id ?? 0
            }
            Item {
                width: 1
                height: acts.visible ? root.u(14) : 0
            }
            Row {
                id: acts
                visible: root.actions.length > 0 || root.entry?.reply
                spacing: root.u(root.N.actionGap)
                Repeater {
                    model: root.actions
                    ActionButton {
                        required property var modelData
                        s: root.s
                        dpr: root.dpr
                        enabled: root.entry?.alive !== false
                        text: String(modelData.label)
                        onClicked: root.actionClicked(root.entry.id, String(modelData.id))
                    }
                }
            }
        }

        // The page and the ×, on the right.
        Row {
            id: side
            anchors.right: parent.right
            anchors.rightMargin: root.u(root.N.critSide)
            y: root.u(36)
            spacing: root.u(14)

            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.entries.length > 1
                spacing: root.u(10)
                Tri {
                    left: true
                    end: root.page === 0
                    onTapped: root.pageStepped(-1)
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    role: "bandTime"
                    font.pixelSize: Tokens.px(18, root.s)
                    font.letterSpacing: 2 * root.s
                    font.features: ({ "tnum": 1 })
                    text: Strings.notify.page.arg(root.page + 1).arg(root.entries.length)
                    color: Tokens.notify.bandText2
                }
                Tri {
                    left: false
                    end: root.page >= root.entries.length - 1
                    onTapped: root.pageStepped(1)
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: root.u(root.N.critClose)
                height: width
                color: "transparent"
                border.width: Tokens.hair(2 * root.s, root.dpr)
                border.color: Tokens.notify.bandText2
                Label {
                    anchors.centerIn: parent
                    s: root.s
                    role: "bandAction"
                    text: Strings.notify.close
                    color: Tokens.notify.bandText
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.entry) root.closeClicked(root.entry.id)
                }
            }
        }
    }

    // ◂ / ▸
    component Tri: Canvas {
        id: tri
        property bool left: true
        property bool end: false
        signal tapped()
        anchors.verticalCenter: parent.verticalCenter
        width: root.u(11)
        height: root.u(16)
        opacity: end ? 0.3 : 1
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Tokens.notify.bandText2;
            ctx.beginPath();
            if (left) {
                ctx.moveTo(width, 0);
                ctx.lineTo(0, height / 2);
                ctx.lineTo(width, height);
            } else {
                ctx.moveTo(0, 0);
                ctx.lineTo(width, height / 2);
                ctx.lineTo(0, height);
            }
            ctx.closePath();
            ctx.fill();
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -root.u(6)
            enabled: !tri.end
            cursorShape: Qt.PointingHandCursor
            onClicked: tri.tapped()
        }
    }

    // Appearing: the band sweeps in from the left (200 ms in the mockup), unless instant.
    NumberAnimation {
        id: sweep
        target: reveal
        property: "width"
        from: 0
        to: root.width
        duration: 200
        easing.type: Easing.OutCubic
    }
    Component.onCompleted: {
        if (sweepIn && !instant)
            sweep.start();
    }
    onWidthChanged: if (!sweep.running) reveal.width = width
}
