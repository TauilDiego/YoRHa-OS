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

// Design system gallery (US3, FR-016): every piece in every state, each with its name, laid out
// like a NieR menu page. Full screen on the Overlay layer; opened and closed over IPC
// (shell.qml loads it through a LazyLoader). Esc emits closeRequested().
// No screen is set: the compositor puts it on the focused output.
// Layout is in game px for a 1920×1080 page and scales with s = height / 1080.
PanelWindow {
    id: root

    signal closeRequested()

    readonly property real s: height > 0 ? height / 1080 : 1
    readonly property var states4: ["normal", "hovered", "selected", "dimmed"]
    readonly property var stateNames: ({
        normal: Strings.gallery.stateNormal,
        hovered: Strings.gallery.stateHovered,
        selected: Strings.gallery.stateSelected,
        dimmed: Strings.gallery.stateDimmed
    })

    // Page grid (game px): margins, three columns, gaps.
    readonly property real colW: 560
    readonly property real colGap: 58
    readonly property real bodyY: 160
    readonly property real sectionGap: 32

    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rien-gallery"
    // false while closing: drop the exclusive focus before the window goes away (shell.qml).
    property bool keyboardActive: true
    WlrLayershell.keyboardFocus: keyboardActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: Tokens.color.darkYellow

    // A named block: the section name (small) above its content.
    component Section: Column {
        id: section
        property string name
        spacing: root.u(12)
        Label {
            s: root.s
            role: "small"
            text: section.name
        }
    }

    // The name under or beside a sample.
    component Caption: Label {
        s: root.s
        role: "button"
        color: Tokens.color.mediumGray
    }

    // One row of the primitives table: name on the left, sample on the right.
    component SampleRow: Item {
        id: sampleRow
        property string name
        default property alias sample: slot.data
        width: root.u(root.colW)
        Caption {
            anchors.verticalCenter: parent.verticalCenter
            text: sampleRow.name
        }
        Item {
            id: slot
            x: root.u(150)
            width: parent.width - x
            height: parent.height
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()

        GridBackground {
            anchors.fill: parent
            s: root.s
        }

        PageHeader {
            x: root.u(Tokens.space.pageMarginH)
            y: root.u(Tokens.space.pageMarginV)
            s: root.s
            title: Strings.gallery.title
            subtitle: Strings.gallery.subtitle
        }

        Rule {
            x: root.u(Tokens.space.pageMarginH)
            y: root.u(128)
            width: parent.width - 2 * x
            s: root.s
        }

        // --- column 1: primitives, header button, selector ----------------------------------
        Column {
            x: root.u(Tokens.space.pageMarginH)
            y: root.u(root.bodyY)
            spacing: root.u(root.sectionGap)

            Section {
                name: Strings.gallery.primitives

                Column {
                    spacing: root.u(10)

                    SampleRow {
                        name: Strings.gallery.square
                        height: root.u(30)
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.u(12)
                            Square { s: root.s }
                            Caption { anchors.verticalCenter: parent.verticalCenter; text: Strings.gallery.squareInk }
                            Item { width: root.u(18); height: 1 }
                            Square { s: root.s; color: Tokens.color.lightYellow }
                            Caption { anchors.verticalCenter: parent.verticalCenter; text: Strings.gallery.squareLight }
                        }
                    }

                    Label {
                        s: root.s
                        role: "button"
                        text: Strings.gallery.rules
                    }

                    SampleRow {
                        name: Strings.gallery.rulePlain
                        height: root.u(30)
                        Rule {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            s: root.s
                        }
                    }

                    SampleRow {
                        name: Strings.gallery.ruleDotted
                        height: root.u(36)
                        Rule {
                            y: root.u(4)
                            width: parent.width
                            s: root.s
                            kind: "dotted"
                        }
                    }

                    SampleRow {
                        name: Strings.gallery.ruleVertical
                        height: root.u(60)
                        Rule {
                            height: parent.height
                            s: root.s
                            kind: "vertical"
                        }
                    }

                    SampleRow {
                        name: Strings.gallery.grid
                        height: root.u(60)
                        // The page itself is the grid; the swatch frames a piece of it.
                        Item {
                            width: root.u(200)
                            height: parent.height
                            GridBackground {
                                anchors.fill: parent
                                s: root.s
                            }
                            Repeater {
                                model: 4
                                Rectangle {
                                    required property int index
                                    readonly property int t: Tokens.line(1, root.s)
                                    x: index === 1 ? parent.width - t : 0
                                    y: index === 3 ? parent.height - t : 0
                                    width: index < 2 ? t : parent.width
                                    height: index < 2 ? parent.height : t
                                    color: Tokens.color.darkGray
                                }
                            }
                        }
                    }
                }
            }

            Section {
                name: Strings.gallery.headerButton

                Grid {
                    columns: 2
                    rowSpacing: root.u(20)
                    columnSpacing: root.u(20)

                    Repeater {
                        model: root.states4
                        Item {
                            id: cell
                            required property string modelData
                            width: button.selectorRoom + button.width
                            height: button.height
                            HeaderButton {
                                id: button
                                x: selectorRoom
                                s: root.s
                                fixedWidth: Tokens.space.tabW
                                text: root.stateNames[cell.modelData]
                                state: cell.modelData
                            }
                        }
                    }
                }
            }

            Section {
                name: Strings.gallery.selector

                Row {
                    spacing: root.u(30)

                    Repeater {
                        model: ["dark", "light"]
                        Column {
                            id: swatch
                            required property string modelData
                            spacing: root.u(8)
                            Rectangle {
                                width: root.u(96)
                                height: root.u(44)
                                color: Tokens.color.lightGray
                                Selector {
                                    anchors.centerIn: parent
                                    s: root.s
                                    tone: swatch.modelData
                                    bobbing: true
                                }
                            }
                            Caption {
                                text: swatch.modelData === "light" ? Strings.gallery.selectorLight : Strings.gallery.selectorDark
                            }
                        }
                    }
                }
            }
        }

        // --- column 2: list item, cursor list ------------------------------------------------
        Column {
            x: root.u(Tokens.space.pageMarginH + root.colW + root.colGap)
            y: root.u(root.bodyY)
            spacing: root.u(root.sectionGap)

            Section {
                name: Strings.gallery.listItem

                Row {
                    spacing: root.u(20)

                    Repeater {
                        model: ["opaque", "plain"]
                        Column {
                            id: variantCol
                            required property string modelData
                            readonly property int railRoom: Tokens.px(Tokens.space.railGap, root.s) + Tokens.line(Tokens.space.rail, root.s)
                            width: root.u((root.colW - 20) / 2)
                            spacing: Tokens.px(Tokens.space.listItemGap, root.s)

                            Caption {
                                bottomPadding: variantCol.railRoom
                                text: variantCol.modelData === "plain" ? Strings.gallery.variantPlain : Strings.gallery.variantOpaque
                            }

                            Repeater {
                                model: root.states4
                                ListItem {
                                    required property string modelData
                                    x: selectorRoom
                                    width: variantCol.width - selectorRoom
                                    s: root.s
                                    variant: variantCol.modelData
                                    text: root.stateNames[modelData]
                                    state: modelData
                                }
                            }
                        }
                    }
                }
            }

            Section {
                name: Strings.gallery.cursorList

                CursorList {
                    width: root.u(root.colW)
                    s: root.s
                    focus: true
                    model: Strings.gallery.sampleList
                    currentIndex: 1
                }
            }
        }

        // --- column 3: page header, card, meter ----------------------------------------------
        Column {
            x: root.u(Tokens.space.pageMarginH + 2 * (root.colW + root.colGap))
            y: root.u(root.bodyY)
            spacing: root.u(root.sectionGap)

            Section {
                name: Strings.gallery.pageHeader

                PageHeader {
                    s: root.s
                    title: Strings.gallery.samplePageTitle
                    subtitle: Strings.gallery.samplePageSubtitle
                }
            }

            Section {
                name: Strings.gallery.card

                Card {
                    width: root.u(Tokens.space.cardW)
                    height: root.u(220)
                    s: root.s
                    title: Strings.gallery.cardTitle
                    Label {
                        s: root.s
                        text: Strings.gallery.cardBody
                    }
                }
            }

            Section {
                name: Strings.gallery.meter

                Row {
                    spacing: root.u(40)

                    Repeater {
                        model: [false, true]
                        Column {
                            id: meterCol
                            required property bool modelData
                            spacing: root.u(8)
                            Meter {
                                s: root.s
                                value: meterCol.modelData ? 0.12 : 0.62
                                critical: meterCol.modelData
                            }
                            Caption {
                                text: meterCol.modelData ? Strings.gallery.meterCritical : Strings.gallery.meterNormal
                            }
                        }
                    }
                }
            }
        }

        // --- bottom: tab bar (columns 1–2) -------------------------------------------------
        Section {
            x: root.u(Tokens.space.pageMarginH)
            y: root.u(880)
            name: Strings.gallery.tabBar

            // Interactive: hover paints a tab, a click selects it.
            TabBar {
                id: galleryTabs
                property int selected: 2
                width: root.u(2 * root.colW + root.colGap)
                s: root.s
                model: Strings.gallery.sampleTabs.map((label, i) => ({
                    label: label,
                    state: i === selected ? "selected" : i === hoveredIndex ? "hovered" : "normal"
                }))
                onActivated: index => selected = index
            }
        }

        Vignette {
            anchors.fill: parent
            s: root.s
            enabled: Settings.vignette
        }
    }
}
