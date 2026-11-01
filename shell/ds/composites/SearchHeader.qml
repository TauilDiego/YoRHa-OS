pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../primitives"
import "../../strings"

// Search header (spec 007): the line on top of a list while the user types, as in the pause menu's
// mockup: SEARCH (small, ink), the query in a light-yellow box with a blinking text cursor (still
// when Tokens.instant), and "N RESULTS" on the right (small, medium-gray). A line of 30 game px.
// The parent sets the width.
Item {
    id: root

    property real s: 1
    property string query
    property int count: 0

    implicitWidth: Tokens.px(380, s)
    implicitHeight: Tokens.px(30, s)

    Label {
        id: searchLabel
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        role: "small"
        text: Strings.pause.search
    }

    Rectangle {
        id: box
        x: Math.ceil(searchLabel.implicitWidth) + Tokens.px(12, root.s)
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, Math.min(root.width - x - Math.ceil(countLabel.implicitWidth) - Tokens.px(12, root.s),
                                    Math.max(Tokens.px(120, root.s), Math.ceil(queryLabel.implicitWidth) + Tokens.px(8 + 4 + 8, root.s))))
        height: Tokens.px(30, root.s)
        color: Tokens.color.lightYellow

        Label {
            id: queryLabel
            x: Tokens.px(8, root.s)
            width: Math.max(0, Math.min(implicitWidth, box.width - x - Tokens.px(12, root.s)))
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            role: "small"
            font.weight: Font.DemiBold
            font.variableAxes: ({ "wght": Font.DemiBold })
            font.letterSpacing: root.s
            elide: Text.ElideLeft
            text: root.query
        }

        // The text cursor: 2 × 18, blinking once a second (still when nothing may move).
        Rectangle {
            id: caret
            x: queryLabel.x + queryLabel.width + Tokens.px(2, root.s)
            anchors.verticalCenter: parent.verticalCenter
            width: Tokens.line(2, root.s)
            height: Tokens.px(18, root.s)
            color: Tokens.color.darkGray
            visible: Tokens.instant || blink.on

            Timer {
                id: blink
                property bool on: true
                interval: 500
                repeat: true
                running: !Tokens.instant && root.visible
                onTriggered: on = !on
                onRunningChanged: on = true
            }
        }
    }

    Label {
        id: countLabel
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        s: root.s
        role: "small"
        text: root.count === 1 ? Strings.pause.oneResult : Strings.pause.results.arg(root.count)
        color: Tokens.color.mediumGray
    }
}
