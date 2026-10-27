pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../ds/composites"
import "../services"
import "../strings"

// The HUD (FR-009–FR-014): one bar at the top of each monitor, reserving its height.
// Left → right: the brand (the TabBar's vertical strips), workspace tabs, the active window's
// title (centered), CPU/MEM/VOL/BAT readings, date and time; the dotted rule along the bottom.
PanelWindow {
    id: root

    property var modelData                       // the ShellScreen, from Variants
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Settings.barHeight
    exclusiveZone: implicitHeight
    WlrLayershell.namespace: "rien-os-hud"
    color: Tokens.color.darkYellow

    // Surface factor (research R5): the tab is 31/40 of the bar, the game's tab is 47.
    readonly property real tabH: Settings.barHeight * 31 / 40
    readonly property real s: tabH / Tokens.space.tabH * Settings.uiScale
    readonly property int margin: Tokens.px(14, s)

    // --- data ---------------------------------------------------------------------------------
    readonly property string monitorName: modelData?.name ?? ""
    readonly property var workspaces: Compositor.workspacesFor(monitorName)

    // Tab states as the compositor sees them: selected (focused), normal (exists), dimmed.
    readonly property var tabs: workspaces.map(w => ({
        label: String(w.id).padStart(2, "0"),
        state: w.focused ? "selected" : w.exists ? "normal" : "dimmed"
    }))

    readonly property var readings: [Telemetry.cpu, Telemetry.mem, Audio.vol, Battery.bat]

    // What the bar shows, for `hud dump` (contracts/ipc.md).
    function dumpEntry(): var {
        return {
            monitor: monitorName,
            height: height,
            tabs: tabs.map((t, i) => Object.assign({ label: t.label, state: t.state }, tabBar.tabGeometry(i))),
            title: Compositor.activeTitle,
            readings: readings.map(r => ({
                key: r.key,
                label: r.label,
                value: Math.round(r.value * 100),
                critical: r.critical,
                extra: r.extra,
                available: r.available
            })),
            date: Clock.dateText,
            time: Clock.timeText
        };
    }

    // --- surface ------------------------------------------------------------------------------
    GridBackground {
        anchors.fill: parent
    }

    // Tabs + strips + the dotted rule, sitting on the bar's bottom edge. The rule's pattern is
    // scaled down to fit under a 31 px tab inside the 40 px bar.
    TabBar {
        id: tabBar
        x: root.margin
        y: root.height - implicitHeight
        width: root.width - 2 * root.margin
        s: root.s
        ruleGap: 3
        ruleScale: root.s * 0.3
        showSelector: false                      // the owner's call: just the tabs, no Pod cursor
        model: root.tabs.map((t, i) => ({
            label: t.label,
            state: i === tabBar.hoveredIndex && t.state !== "selected" ? "hovered" : t.state
        }))
        onActivated: index => {
            const ws = root.workspaces[index];
            if (ws)
                Compositor.focus(ws.id);
        }
    }

    // The band the tabs sit on: everything else centers vertically on it.
    Item {
        id: band
        y: tabBar.y
        width: root.width
        height: tabBar.bandH

        // Active window title: centered on the bar, shrinking (elided) between the tabs and
        // the readings, never pushing them.
        Label {
            id: title
            readonly property int gap: Tokens.px(26, root.s)
            readonly property real leftEdge: tabBar.x + tabBar.implicitWidth + gap
            readonly property real rightEdge: status.x - gap
            readonly property real half: Math.max(0, Math.min(root.width / 2 - leftEdge, rightEdge - root.width / 2))
            x: Math.round(root.width / 2 - half)
            width: Math.round(2 * half)
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            role: "small"
            color: Tokens.color.mediumGray
            text: Compositor.activeTitle
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: width > 0
        }

        Row {
            id: status
            anchors.right: parent.right
            anchors.rightMargin: root.margin
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.px(26, root.s)

            Repeater {
                model: root.readings.length

                ReadingView {
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    reading: root.readings[index]
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.px(14, root.s)

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    role: "headerButton"
                    color: Tokens.color.mediumGray
                    text: Clock.dateText
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    role: "headerButton"
                    text: Clock.timeText
                }
            }
        }
    }

    // One reading: label, meter, integer percent (+ charging / muted marks).
    component ReadingView: Row {
        id: view
        property var reading: ({})
        readonly property bool muted: reading.extra === "muted"
        readonly property bool charging: reading.extra === "charging"

        visible: reading.available === true
        spacing: Tokens.px(8, root.s)

        Label {
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            role: "small"
            text: view.reading.label ?? ""
        }
        Meter {
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            w: 82
            value: view.reading.value ?? 0
            critical: view.reading.critical === true
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            // Fixed room for "100", so live values never shift their neighbours.
            width: Math.max(implicitWidth, widest.implicitWidth)
            s: root.s
            role: "small"
            color: view.reading.critical ? Tokens.color.alert : Tokens.color.mediumGray
            text: view.muted ? Strings.muted
                             : Math.round((view.reading.value ?? 0) * 100) + (view.charging ? Strings.charging : "")
            Label {
                id: widest
                visible: false
                s: root.s
                role: "small"
                text: "100"
            }
        }
    }
}
