pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../ds/composites"
import "../strings"

// The gallery's page 7 (spec 013): the pieces of the game's motion. The scrolling label (FR-012)
// with a text that fits, one that does not, two copies scrolling as one (the ListItem's dark and
// light faces) and the cut of Reduce motion (FR-016); the typed text with the tip letter (FR-004),
// typing again every few seconds. Front A: a list whose cursor moves on its own (the selection's
// sweep and fold, the pulse) and comes in again in cascade, and a title that changes the game's way.
Rectangle {
    id: root

    property real s: 1
    property real dpr: 1

    readonly property var gs: Strings.gallery
    readonly property int boxW: u(300)

    function u(v: real): int {
        return Tokens.px(v, s);
    }

    color: Tokens.color.darkYellow

    component Caption: Label {
        s: root.s
        role: "small"
        color: Tokens.color.darkGray
        opacity: 0.7
    }
    // A sample's box: a hairline frame boxW wide, the sample inside.
    component Box: Rectangle {
        width: root.boxW + 2 * root.u(12)
        height: root.u(48)
        color: Tokens.color.lightGray
        border.width: Tokens.hair(1, root.dpr)
        border.color: Tokens.color.darkGray
    }

    PageHeader {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(Tokens.space.pageMarginV)
        s: root.s
        title: root.gs.title
        subtitle: root.gs.page7Subtitle
    }

    // spec 013, front C: the choice pop-up on the right of the page, in two panels of paper (the menu's
    // body in miniature): one value to pick, and several marks with a list that scrolls in whole rows.
    Column {
        x: root.width - root.u(Tokens.space.pageMarginH) - root.u(600)
        y: root.u(220)
        spacing: root.u(14)

        Label {
            s: root.s
            role: "subheader"
            text: root.gs.choicePopup
        }
        Rectangle {
            id: singlePanel
            width: root.u(600)
            height: root.u(400)
            color: Tokens.color.darkYellow
            border.width: Tokens.hair(1, root.dpr)
            border.color: Tokens.color.darkGray
            clip: true
            ChoicePopup {
                anchors.fill: parent
                s: root.s
                open: true
                values: root.gs.choiceSample
                current: 1
                anchorX: root.u(24)
                anchorY: root.u(30)
                limitTop: root.u(10)
                limitBottom: parent.height - root.u(10)
            }
        }
        Caption { text: root.gs.choiceSingle }
        Rectangle {
            width: root.u(600)
            height: root.u(280)
            color: Tokens.color.darkYellow
            border.width: Tokens.hair(1, root.dpr)
            border.color: Tokens.color.darkGray
            clip: true
            ChoicePopup {
                anchors.fill: parent
                s: root.s
                open: true
                multi: true
                values: ["English (US)", "Portuguese (Brazil)", "Portuguese (Portugal)", "Spanish", "German", "French"]
                marked: [0, 1]
                current: 1
                anchorX: root.u(24)
                anchorY: root.u(150)
                limitTop: root.u(10)
                limitBottom: parent.height - root.u(10)
            }
        }
        Caption { text: root.gs.choiceMulti }
    }

    Column {
        x: root.u(Tokens.space.pageMarginH)
        y: root.u(220)
        spacing: root.u(18)

        Label {
            s: root.s
            role: "subheader"
            text: root.gs.scrollingLabel
        }

        Row {
            spacing: root.u(40)
            Column {
                spacing: root.u(8)
                Box {
                    ScrollingLabel {
                        x: root.u(12)
                        width: root.boxW
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        role: "listButton"
                        text: root.gs.shortText
                    }
                }
                Caption { text: root.gs.fits }
            }
            Column {
                spacing: root.u(8)
                Box {
                    ScrollingLabel {
                        objectName: "galleryMarquee"
                        x: root.u(12)
                        width: root.boxW
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        role: "listButton"
                        text: root.gs.longText
                    }
                }
                Caption { text: root.gs.scrolls }
            }
        }

        Row {
            spacing: root.u(40)
            Column {
                spacing: root.u(8)
                // The dark copy over the paper, the light one over the left half's ink, clipped.
                Box {
                    id: pair
                    ScrollingLabel {
                        id: leader
                        x: root.u(12)
                        width: root.boxW
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        role: "listButton"
                        text: root.gs.longText
                    }
                    Rectangle {
                        width: Math.round(pair.width / 2)
                        height: pair.height
                        color: Tokens.color.darkGray
                        clip: true
                        ScrollingLabel {
                            x: root.u(12)
                            width: root.boxW
                            anchors.verticalCenter: parent.verticalCenter
                            s: root.s
                            role: "listButton"
                            text: root.gs.longText
                            color: Tokens.color.lightYellow
                            follow: leader
                        }
                    }
                }
                Caption { text: root.gs.synced }
            }
            Column {
                spacing: root.u(8)
                Box {
                    Label {
                        x: root.u(12)
                        width: root.boxW
                        anchors.verticalCenter: parent.verticalCenter
                        s: root.s
                        role: "listButton"
                        text: root.gs.longText
                        elide: Text.ElideRight
                    }
                }
                Caption { text: root.gs.cut }
            }
        }

        Item { width: 1; height: root.u(20) }

        Label {
            s: root.s
            role: "subheader"
            text: root.gs.typedTip
        }
        Box {
            TypedText {
                id: typed
                x: root.u(12)
                width: root.boxW
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                role: "subheader"
                color: Tokens.color.darkGray
                maxLines: 1
                text: root.gs.typedSample
                cps: Tokens.motion.titleCps
                tip: "letter"
                instant: Tokens.instant
            }
            Timer {
                interval: 3000
                running: true
                repeat: true
                onTriggered: typed.restartKey = typed.restartKey + 1
            }
        }
    }

    // --- spec 013, front A: the list and the title, moving on their own ---------------------------
    Column {
        x: root.u(1000)
        y: root.u(220)
        spacing: root.u(18)

        Label {
            s: root.s
            role: "subheader"
            text: root.gs.motionList
        }
        CursorList {
            id: demoList
            width: root.u(520)
            s: root.s
            model: root.gs.motionItems
            keysEnabled: false
        }
        Caption { text: root.gs.motionListNote }

        Item { width: 1; height: root.u(20) }

        Label {
            s: root.s
            role: "subheader"
            text: root.gs.motionTitle
        }
        PageHeader {
            id: demoTitle
            property int k: 0
            s: root.s
            animated: true
            title: root.gs.motionTitles[k][0]
            subtitle: root.gs.motionTitles[k][1]
        }
    }
    Timer {
        interval: 1600
        running: root.visible && !Tokens.instant
        repeat: true
        onTriggered: {
            demoList.move(1);
            if (demoList.currentIndex === demoList.count - 1)
                demoList.currentIndex = 0;
        }
    }
    Timer {
        interval: 8000
        running: root.visible && !Tokens.instant
        repeat: true
        onTriggered: {
            demoList.enter(0, -1);
            demoTitle.k = (demoTitle.k + 1) % root.gs.motionTitles.length;
        }
    }
}
