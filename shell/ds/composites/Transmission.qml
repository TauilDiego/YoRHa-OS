pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../base"
import "../../strings"

// A transmission (spec 008, FR-003, FR-009–FR-014; contracts/components.md): a notification on the
// band, as the Pod speaks. Top to bottom: who speaks (the square, the name, ×N, the CRITICAL tag,
// the time on the right; the × in its place with the pointer over it), the title on one line, the
// typed body (at most Tokens.notify.lines; an image of 72 on its right), "More in log" when the body
// is cut, the progress meter, up to 3 action buttons (and Reply), the reply field, and a thin time
// line along the bottom that shrinks with the time left.
//   entry: an Entry of NotifyStore (data-model); layout: "corner" | "top" | "subtitle" | "preview"
//   (the middle of the text log: no time line, no ×, up to Tokens.notify.previewLines; its actions
//   dim when the app no longer listens: `live: false`).
//   typeFrom / typeMs / typeKey: the typing (TypedText); lifeFrac / lifeMs / paused: the time line,
//   which shrinks from lifeFrac to 0 in lifeMs unless paused.
// The parent sets the width; the height follows the content.
Item {
    id: root

    property real s: 1
    property real dpr: 1
    property var entry: ({})
    property string speaker
    property int count: 1
    property string layout: "corner"
    property bool instant: false
    property int typeFrom: 0
    property int typeMs: 0
    property var typeKey: 0
    property real lifeFrac: 1
    property int lifeMs: 0
    property bool paused: false
    property bool showLife: true
    property bool replying: false
    property bool live: true                     // the app still listens (preview: false dims the actions)
    property var arcs: [[640, 250, 230, 180, 280], [640, 250, 237, 180, 280], [-60, 330, 260, 290, 340]]

    signal typedOut()
    signal clicked(int button)
    signal closeClicked()
    signal actionClicked(string id)
    signal replyOpened()
    signal replySent(string text)
    signal replyCancelled()
    signal hoverChanged(bool hovering)

    readonly property bool preview: layout === "preview"
    readonly property bool hovering: hover.hovered
    readonly property bool typing: body.typing
    readonly property bool truncated: body.truncated
    readonly property var N: Tokens.notify
    readonly property string urgency: String(entry?.urgency ?? "normal")
    readonly property color blockColor: urgency === "low" ? Tokens.color.mediumGray
                                      : urgency === "critical" ? Tokens.color.alert : Tokens.color.lightYellow
    readonly property var actions: (Array.isArray(entry?.actions) ? entry.actions : []).slice(0, N.maxActions)
    readonly property bool hasReply: entry?.reply !== null && entry?.reply !== undefined
    readonly property bool hasImage: String(entry?.image ?? "") !== ""
    readonly property bool hasProgress: entry?.progress !== null && entry?.progress !== undefined
    readonly property bool hasBody: String(entry?.body ?? "") !== ""

    function u(v: real): int {
        return Tokens.px(v, s);
    }
    function complete(): void {
        body.complete();
    }

    readonly property int padTop: u(layout === "top" ? 12 : N.padTop)
    readonly property int padBottom: u(layout === "top" ? 14 : N.padBottom)
    readonly property int contentX: layout === "top" ? u(N.topPad) : u(layout === "subtitle" ? N.subtitlePadLeft : N.padLeft)
    readonly property int contentW: width - contentX - (layout === "top" ? u(N.topPad) : u(N.padRight))

    implicitWidth: u(N.stackW)
    implicitHeight: padTop + column.height + padBottom

    Band {
        anchors.fill: parent
        s: root.s
        dpr: root.dpr
        arcs: root.arcs
        block: root.blockColor
        shadow: !root.preview && root.layout !== "top"
    }

    HoverHandler {
        id: hover
        onHoveredChanged: root.hoverChanged(hovered)
    }
    MouseArea {
        anchors.fill: parent
        enabled: !root.preview
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (!root.replying || mouse.button === Qt.RightButton)
                root.clicked(mouse.button);
        }
    }

    Column {
        id: column
        x: root.contentX
        y: root.padTop
        width: root.contentW

        // Who speaks.
        Item {
            id: who
            width: parent.width
            height: Math.max(nameLabel.implicitHeight, tag.visible ? tag.height : 0)

            Row {
                id: whoRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.u(10)
                width: parent.width - timeLabel.width - root.u(14)

                Square {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    size: root.N.who
                    color: Tokens.notify.bandText
                }
                Label {
                    id: nameLabel
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, whoRow.width - x - (countLabel.visible ? countLabel.width + whoRow.spacing : 0)
                                    - (tag.visible ? tag.width + whoRow.spacing : 0))
                    s: root.s
                    role: "bandWho"
                    elide: Text.ElideRight
                    text: root.speaker
                    color: Tokens.notify.bandText
                }
                Label {
                    id: countLabel
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.count > 1
                    s: root.s
                    role: "bandWho"
                    font.weight: Font.Medium
                    font.variableAxes: ({ "wght": Font.Medium })
                    font.letterSpacing: root.s
                    text: Strings.notify.count.arg(root.count)
                    color: Tokens.notify.bandText2
                }
                Tag {
                    id: tag
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.urgency === "critical"
                    s: root.s
                    dpr: root.dpr
                    text: Strings.notify.critical
                }
            }
            Label {
                id: timeLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.preview || !root.hovering
                s: root.s
                role: "bandTime"
                font.features: ({ "tnum": 1 })
                text: Qt.formatDateTime(new Date(Number(root.entry?.at ?? 0)), Strings.notify.timeFormat)
                color: Tokens.notify.bandText2
            }
        }

        Item {
            width: 1
            height: root.u(root.N.titleGap)
        }
        Label {
            id: titleLabel
            width: parent.width
            s: root.s
            role: "bandTitle"
            textFormat: Text.PlainText
            elide: Text.ElideRight
            maximumLineCount: 1
            text: String(root.entry?.title ?? "")
            color: Tokens.notify.bandText
        }

        Item {
            width: 1
            height: root.hasBody || root.hasImage ? root.u(root.N.bodyGap) : 0
        }
        Item {
            id: bodyRow
            width: parent.width
            visible: root.hasBody || root.hasImage
            height: Math.max(root.hasBody ? body.height : 0, root.hasImage ? image.y + image.height + root.u(4) : 0)

            TypedText {
                id: body
                width: parent.width - (root.hasImage ? image.width + root.u(16) : 0)
                visible: root.hasBody
                s: root.s
                text: String(root.entry?.body ?? "")
                from: root.typeFrom
                ms: root.typeMs
                restartKey: root.typeKey
                instant: root.instant
                maxLines: root.preview ? root.N.previewLines : root.N.lines
                onDone: root.typedOut()
            }
            Image {
                id: image
                anchors.right: parent.right
                y: root.u(4)
                visible: root.hasImage
                width: root.u(root.N.imageSize)
                height: width
                source: root.hasImage ? String(root.entry.image) : ""
                sourceSize.width: Math.round(width * root.dpr)
                sourceSize.height: Math.round(height * root.dpr)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: Tokens.hair(root.N.imageFrame * root.s, root.dpr)
                    border.color: Tokens.notify.bandText2
                }
            }
        }

        Item {
            width: 1
            height: moreLabel.visible ? root.u(6) : 0
        }
        Label {
            id: moreLabel
            visible: !root.preview && root.truncated
            s: root.s
            role: "bandMore"
            text: Strings.notify.moreInLog
            color: Tokens.notify.bandText2
        }

        Item {
            width: 1
            height: root.hasProgress ? root.u(root.N.progressGap) : 0
        }
        Item {
            id: progress
            visible: root.hasProgress
            width: parent.width
            height: Math.max(track.height, progressNum.implicitHeight)

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - progressNum.width - root.u(14)
                height: Tokens.px(Tokens.space.meterH, root.s)
                color: Tokens.notify.bandTrack
                Rectangle {
                    width: Math.round(parent.width * Math.max(0, Math.min(100, Number(root.entry?.progress ?? 0))) / 100)
                    height: parent.height
                    color: Tokens.color.lightYellow
                }
            }
            Label {
                id: progressNum
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: root.u(root.N.progressNumW)
                s: root.s
                role: "bandBody"
                font.features: ({ "tnum": 1 })
                horizontalAlignment: Text.AlignRight
                text: `${Number(root.entry?.progress ?? 0)}%`
                color: Tokens.notify.bandText
            }
        }

        Item {
            width: 1
            height: buttons.visible ? root.u(14) : 0
        }
        Row {
            id: buttons
            visible: !root.replying && (root.actions.length > 0 || root.hasReply)
            spacing: root.u(root.N.actionGap)

            Repeater {
                model: root.actions
                ActionButton {
                    required property var modelData
                    s: root.s
                    dpr: root.dpr
                    enabled: root.live
                    text: String(modelData.label)
                    onClicked: root.actionClicked(String(modelData.id))
                }
            }
            ActionButton {
                visible: root.hasReply
                s: root.s
                dpr: root.dpr
                enabled: root.live
                text: String(root.entry?.reply?.label || Strings.notify.reply)
                onClicked: root.replyOpened()
            }
        }

        // The reply field: the only moment a transmission takes the keyboard (FR-014).
        Item {
            width: 1
            height: replyRow.visible ? root.u(14) : 0
        }
        Item {
            id: replyRow
            visible: root.replying
            width: parent.width
            height: root.u(root.N.replyH)

            Rectangle {
                id: field
                width: parent.width - hint.width - root.u(10)
                height: parent.height
                color: Tokens.notify.replyField
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Tokens.hair(2 * root.s, root.dpr)
                    color: Tokens.notify.bandText
                }
                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: root.u(10)
                    anchors.rightMargin: root.u(10)
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    color: Tokens.notify.bandText
                    selectionColor: Tokens.color.lightYellow
                    selectedTextColor: Tokens.color.darkGray
                    font.family: Tokens.type.bandBody.family
                    font.pixelSize: Tokens.px(Tokens.type.bandBody.size, root.s)
                    font.weight: Font.Medium
                    font.variableAxes: ({ "wght": Font.Medium })
                    Keys.onReturnPressed: if (text.trim() !== "") root.replySent(text.trim())
                    Keys.onEnterPressed: if (text.trim() !== "") root.replySent(text.trim())
                    Keys.onEscapePressed: root.replyCancelled()
                }
            }
            Label {
                id: hint
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                role: "bandTime"
                text: Strings.notify.send + " · " + Strings.notify.cancel
                color: Tokens.notify.bandText2
            }
        }
    }
    onReplyingChanged: {
        input.text = "";
        if (replying)
            input.forceActiveFocus();
    }
    function focusReply(): void {
        input.forceActiveFocus();
    }

    // The × in place of the time, with the pointer over the transmission.
    Rectangle {
        id: closeBox
        visible: !root.preview && root.hovering
        anchors.right: parent.right
        anchors.rightMargin: root.layout === "top" ? root.u(300) : root.u(10)
        y: root.u(9)
        width: root.u(root.N.closeSize)
        height: width
        color: Qt.rgba(0x1E / 255, 0x1D / 255, 0x19 / 255, 0.9)
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
            onClicked: root.closeClicked()
        }
    }

    // The time left (FR-003): shrinks to nothing; still while paused; none when instant (FR-031).
    property real life: 1
    Rectangle {
        visible: root.showLife && !root.preview && !root.instant && root.lifeMs > 0
        x: root.u(root.N.block)
        anchors.bottom: parent.bottom
        width: Math.round((root.width - x) * root.life)
        height: root.u(root.N.lifeH)
        color: Tokens.notify.bandText2
    }
    NumberAnimation {
        id: lifeAnim
        target: root
        property: "life"
        to: 0
        easing.type: Easing.Linear
    }
    function arm(): void {
        lifeAnim.stop();
        life = Math.max(0, Math.min(1, lifeFrac));
        if (!paused && lifeMs > 0 && !instant) {
            lifeAnim.from = life;
            lifeAnim.duration = lifeMs;
            lifeAnim.start();
        }
    }
    onLifeFracChanged: Qt.callLater(arm)
    onLifeMsChanged: Qt.callLater(arm)
    onPausedChanged: Qt.callLater(arm)
    Component.onCompleted: arm()
}
