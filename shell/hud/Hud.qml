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
// spec 004 US6: the bar has no background of its own. The monitor's wallpaper (and its
// transitions) shows under it, and its colors follow that wallpaper: `tone`, 0 paper → 1 light,
// from WallpaperStore.toneMix (set by the monitor's Wallpaper), handed to every piece.
// 004 acabamento: `high` (Settings.barContrast, System Settings › Appearance › Bar contrast):
// over paper, a darker ink for every text, a paper plate behind the texts (fading out toward the
// light tone, where it is not drawn) and a heavier clock.
PanelWindow {
    id: root

    property var modelData                       // the ShellScreen, from Variants
    screen: modelData

    signal logRequested()                        // spec 008: a click on the unread counter

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Settings.barHeight
    exclusiveZone: implicitHeight
    WlrLayershell.namespace: "yorha-os-hud"
    color: "transparent"

    // Layout, top to bottom: a little room, the tabs, a visible gap, then the dotted rule.
    // The tab takes a fixed share of the bar; s (research R5) scales the game's 47 px tab to it.
    readonly property real tabShare: 0.485             // 33 px of the default 68
    readonly property real ruleGap: 17                   // game px between the tabs and the rule
    readonly property real ruleShare: 1.0                // the rule's pattern, relative to s: the game's own size
    readonly property real tabH: Math.round(Settings.barHeight * tabShare)
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

    // spec 004 US6: this monitor's tone (0 paper → 1 light).
    readonly property real tone: WallpaperStore.toneMix[monitorName] ?? 0
    readonly property bool high: Settings.barContrast === "high"
    function ink(role: string): color {
        return Tokens.hudColorAt(role, root.tone, root.high);
    }
    // The High plate behind the texts: paper at 55% over paper, gone in the light tone.
    readonly property color plate: Qt.rgba(Tokens.hudHighPlate.r, Tokens.hudHighPlate.g, Tokens.hudHighPlate.b,
                                           Tokens.hudHighPlate.a * Math.max(0, 1 - root.tone))
    readonly property bool plated: root.high && root.tone < 1

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
            time: Clock.timeText,
            // spec 004 US6 (contracts/ipc.md of spec 004): the tone, and every text's box and
            // color, so the contrast can be measured on the pixels.
            tone: tone >= 0.5 ? "light" : "paper",
            toneMix: Math.round(tone * 1000) / 1000,
            contrast: Settings.barContrast,
            texts: textBoxes(),
            // spec 008 (contracts/ipc.md): the unread counter before the clock
            log: {
                visible: logCounter.visible,
                text: logCounter.visible ? `${logCounter.labelText.text} ${logCounter.valueText.text}` : "",
                box: logCounter.visible ? (() => {
                    const p = logCounter.mapToItem(null, 0, 0);
                    return { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(logCounter.width), h: Math.round(logCounter.height) };
                })() : null
            }
        };
    }

    // --- spec 004 US6: the texts, for `hud dump` -------------------------------------------------
    function hex(c: color): string {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return "#" + h(c.r) + h(c.g) + h(c.b) + h(c.a);
    }
    function textBox(role: string, label: Label): var {
        const p = label.mapToItem(null, 0, 0);
        const dx = label.horizontalAlignment === Text.AlignHCenter ? (label.width - label.paintedWidth) / 2 : 0;
        return {
            role: role,
            text: label.text,
            x: Math.round(p.x + dx),
            y: Math.round(p.y),
            w: Math.round(label.paintedWidth),
            h: Math.round(label.paintedHeight),
            color: hex(label.color),
            plate: root.plated ? hex(root.plate) : ""
        };
    }
    function textBoxes(): var {
        const out = [];
        root.tabs.forEach((t, i) => {
            const g = tabBar.tabGeometry(i);
            const inked = t.state === "selected" || i === tabBar.hoveredIndex;
            out.push({
                role: "tab",
                text: t.label,
                x: g.x,
                y: Math.round(tabBar.y),
                w: g.w,
                h: tabBar.bandH,
                color: hex(root.ink(inked ? "selInk" : t.state === "dimmed" ? "ink2" : "ink")),
                plate: hex(root.ink(inked ? "sel" : "rest"))
            });
        });
        if (title.visible && title.text !== "")
            out.push(textBox("title", title));
        for (let i = 0; i < readingViews.count; i++) {
            const v = readingViews.itemAt(i) as ReadingView;
            if (!v || !v.visible)
                continue;
            out.push(textBox("label", v.labelText), textBox("value", v.valueText));
        }
        if (logCounter.visible)
            out.push(textBox("log", logCounter.labelText), textBox("log", logCounter.valueText));
        out.push(textBox("date", dateText), textBox("time", timeText));
        return out;
    }
    // --- end spec 004 US6 --------------------------------------------------------------------------

    // Tabs + strips + the dotted rule, sitting on the bar's bottom edge.
    TabBar {
        id: tabBar
        x: root.margin
        y: root.height - implicitHeight
        width: root.width - 2 * root.margin
        s: root.s
        tone: root.tone
        high: root.high
        ruleGap: root.ruleGap
        ruleScale: root.s * root.ruleShare
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
            tone: root.tone
            role: "small"
            color: root.ink("ink2")
            text: Compositor.activeTitle
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: width > 0
            Plate {
                x: (title.width - title.paintedWidth) / 2 - padX
                width: title.paintedWidth + 2 * padX
                visible: root.plated && title.text !== ""
            }
        }

        Row {
            id: status
            anchors.right: parent.right
            anchors.rightMargin: root.margin
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.px(26, root.s)

            Repeater {
                id: readingViews
                model: root.readings.length

                ReadingView {
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    reading: root.readings[index]
                }
            }

            // spec 008: LOG 3 / DND 3 (FR-025)
            LogCounter {
                id: logCounter
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                tone: root.tone
                ink: root.ink("ink")
                count: NotifyStore.unread
                dnd: NotifyPrefs.dnd
                plate: root.plate
                plated: root.plated
                onClicked: root.logRequested()
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.px(14, root.s)

                Label {
                    id: dateText
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    tone: root.tone
                    role: "headerButton"
                    color: root.ink("ink2")
                    text: Clock.dateText
                    Plate {}
                }
                Label {
                    id: timeText
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    tone: root.tone
                    role: "headerButton"
                    // High contrast: one step heavier (DemiBold → Bold), on the variable axis too.
                    readonly property int weight: root.high ? Font.Bold : textStyle.weight
                    font.weight: weight
                    font.variableAxes: ({ "wght": weight })
                    color: root.ink("ink")
                    text: Clock.timeText
                    Plate {}
                }
            }
        }
    }

    // The High plate behind a text (its parent): a few px around it, under it (z -1). The padding
    // stays under 4 logical px, inside the box the tests leave out of the bar's empty area.
    component Plate: Rectangle {
        readonly property real padX: 3
        readonly property real padY: 2
        x: -padX
        y: -padY
        z: -1
        readonly property var host: parent        // the Label it sits behind
        width: (host?.paintedWidth ?? 0) + 2 * padX
        height: (host?.paintedHeight ?? 0) + 2 * padY
        color: root.plate
        visible: root.plated
    }

    // One reading: label, meter, integer percent (+ charging / muted marks).
    component ReadingView: Row {
        id: view
        property var reading: ({})
        readonly property bool muted: reading.extra === "muted"
        readonly property bool charging: reading.extra === "charging"
        readonly property Label labelText: readingLabel      // for `hud dump` (spec 004 US6)
        readonly property Label valueText: readingValue

        visible: reading.available === true
        spacing: Tokens.px(8, root.s)

        Label {
            id: readingLabel
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            tone: root.tone
            role: "small"
            color: root.ink("ink")
            text: view.reading.label ?? ""
            // One plate for the whole reading (label, meter, value), behind them; it ends with the
            // value's digits, not with the room kept for "100".
            Plate {
                y: -readingLabel.y - padY
                width: readingValue.x + readingValue.paintedWidth + 2 * padX
                height: view.height + 2 * padY
            }
        }
        Meter {
            anchors.verticalCenter: parent.verticalCenter
            s: root.s
            tone: root.tone
            w: 82
            value: view.reading.value ?? 0
            critical: view.reading.critical === true
        }
        Label {
            id: readingValue
            anchors.verticalCenter: parent.verticalCenter
            // Fixed room for "100", so live values never shift their neighbours.
            width: Math.max(implicitWidth, widest.implicitWidth)
            s: root.s
            tone: root.tone
            role: "small"
            color: root.ink(view.reading.critical ? "alert" : "ink2")
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
