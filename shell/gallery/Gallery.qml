pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../ds/primitives"
import "../ds/base"
import "../ds/composites"
import "../popup"
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

    property int page: 0                      // spec 003: Tab switches to the second page

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
    WlrLayershell.namespace: "yorha-gallery"
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
        Keys.onTabPressed: root.page = (root.page + 1) % 2     // spec 003: the second page

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
                        HeaderButton {
                            required property string modelData
                            s: root.s
                            fixedWidth: Tokens.space.tabW
                            text: root.stateNames[modelData]
                            state: modelData
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
                                    shown: true
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

        // --- spec 003: page 2 (Tab), the settings pop-up's pieces (FR-024, SC-008) -------------
        // Samples come from the settings catalog (SettingsModel), shown as they are.
        Rectangle {
            id: page2
            anchors.fill: parent
            visible: root.page === 1
            color: Tokens.color.darkYellow

            readonly property var states3: ["normal", "focused", "dimmed"]
            readonly property var stateNames3: [Strings.gallery.stateNormal, Strings.gallery.stateFocused, Strings.gallery.stateDimmed]
            // One option of each type, by its place in the default catalog.
            readonly property var samples: [["display", "night"], ["display", "scale"], ["display", "brightness"], ["bluetooth", "pair"], ["power", "battery"]]
            function sample(i: int): var {
                return SettingsModel.find(samples[i][0], samples[i][1]);
            }
            function sampleValue(i: int): var {
                return SettingsModel.value(samples[i][0], samples[i][1]);
            }
            readonly property var keysCategories: [
                { key: Strings.settings.keyUpDown, label: Strings.settings.select },
                { key: Strings.settings.keyRight, label: Strings.settings.open },
                { key: Strings.settings.keyEsc, label: Strings.settings.close }
            ]
            readonly property var keysOption: [
                { key: Strings.settings.keyUpDown, label: Strings.settings.select },
                { key: Strings.settings.keyLeftRight, label: Strings.settings.change },
                { key: Strings.settings.keyEsc, label: Strings.settings.back }
            ]

            PageHeader {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(Tokens.space.pageMarginV)
                s: root.s
                title: Strings.gallery.title
                subtitle: Strings.gallery.page2Subtitle
            }

            Rule {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(128)
                width: parent.width - 2 * x
                s: root.s
            }

            // Option rows: the five types (rows) in three states (columns).
            Repeater {
                model: 3
                Section {
                    id: stateCol
                    required property int index
                    x: root.u(Tokens.space.pageMarginH + index * (root.colW + root.colGap))
                    y: root.u(root.bodyY)
                    name: index === 0 ? Strings.gallery.optionRow + " · " + page2.stateNames3[0] : page2.stateNames3[index]
                    spacing: root.u(12) + Tokens.px(Tokens.space.railGap, root.s) + Tokens.line(Tokens.space.rail, root.s)

                    Column {
                        spacing: Tokens.px(Tokens.space.listItemGap, root.s)
                        Repeater {
                            model: 5
                            OptionRow {
                                required property int index
                                readonly property int selectorRoom: Tokens.px(Tokens.space.selectorW + Tokens.space.selectorGap, root.s)
                                x: selectorRoom
                                width: root.u(root.colW) - selectorRoom - root.u(Tokens.shadow.boxX)
                                s: root.s
                                option: page2.sample(index) ?? ({})
                                value: page2.sampleValue(index)
                                focused: stateCol.index === 1 || (stateCol.index === 2 && index === 3)
                                dimmed: stateCol.index === 2
                            }
                        }
                    }
                }
            }

            // --- bottom, column 1: value stepper, editable meter, key hints
            Column {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(540)
                spacing: root.u(24)

                Section {
                    name: Strings.gallery.valueStepper
                    Repeater {
                        model: [[Strings.gallery.stepperMiddle, 1], [Strings.gallery.stepperStart, 0], [Strings.gallery.stepperEnd, 3]]
                        SampleRow {
                            id: stepRow
                            required property var modelData
                            name: modelData[0]
                            height: root.u(30)
                            ValueStepper {
                                anchors.verticalCenter: parent.verticalCenter
                                s: root.s
                                arrows: true
                                text: page2.sample(1)?.values?.[stepRow.modelData[1]] ?? ""
                                atStart: stepRow.modelData[1] === 0
                                atEnd: stepRow.modelData[1] === 3
                            }
                        }
                    }
                }

                Section {
                    name: Strings.gallery.meter
                    SampleRow {
                        name: Strings.gallery.meterEditable
                        height: root.u(30)
                        Meter {
                            id: editableMeter
                            anchors.verticalCenter: parent.verticalCenter
                            s: root.s
                            w: Tokens.space.sliderW
                            value: 0.7
                            editable: true
                            onPicked: v => value = v
                        }
                    }
                    SampleRow {
                        name: Strings.gallery.meterInverted
                        height: root.u(30)
                        Rectangle {
                            width: root.u(Tokens.space.sliderW + 24)
                            height: parent.height
                            color: Tokens.color.darkGray
                            Meter {
                                anchors.centerIn: parent
                                s: root.s
                                w: Tokens.space.sliderW
                                value: 0.7
                                inverted: true
                            }
                        }
                    }
                }

                Section {
                    name: Strings.gallery.keyHints
                    KeyHints {
                        s: root.s
                        model: page2.keysCategories
                    }
                    KeyHints {
                        s: root.s
                        model: page2.keysOption
                    }
                }
            }

            // --- bottom, column 2: description card with a note
            Section {
                x: root.u(Tokens.space.pageMarginH + root.colW + root.colGap)
                y: root.u(540)
                name: Strings.gallery.descriptionCard + " · " + Strings.gallery.cardWithNote
                DescriptionCard {
                    s: root.s
                    minHeight: 0
                    title: page2.sample(1)?.label ?? ""
                    text: page2.sample(1)?.desc ?? ""
                    note: SettingsModel.needs.bt ?? ""
                    meta: [
                        { label: Strings.settings.defaultLabel, value: SettingsModel.defaultDisplay("display", "scale") },
                        { label: Strings.settings.nowLabel, value: SettingsModel.display("display", "scale") }
                    ]
                }
            }

            // --- bottom, column 3: description card without a note; cursor list without the
            // focus and the pop-up frame, side by side
            Column {
                x: root.u(Tokens.space.pageMarginH + 2 * (root.colW + root.colGap))
                y: root.u(540)
                spacing: root.u(24)

                Section {
                    name: Strings.gallery.descriptionCard
                    DescriptionCard {
                        s: root.s
                        minHeight: 0
                        title: SettingsModel.categories[0]?.label ?? ""
                        text: SettingsModel.categories[0]?.about ?? ""
                        meta: [{ label: Strings.settings.count, value: String(SettingsModel.categories[0]?.options?.length ?? 0) }]
                    }
                }

                Row {
                    spacing: root.u(20)

                    Section {
                        name: Strings.gallery.cursorListUnfocused
                        CursorList {
                            width: root.u(250)
                            s: root.s
                            keysEnabled: false
                            focused: false
                            model: SettingsModel.categories.slice(0, 2).map(c => c.label)
                            currentIndex: 1
                        }
                    }

                    Section {
                        name: Strings.gallery.popupFrame
                        // A miniature desktop under the frame, so the dimming shows.
                        Rectangle {
                            width: root.u(288)
                            height: root.u(162)
                            color: Tokens.color.lightGray
                            clip: true
                            Rectangle {
                                x: root.u(16)
                                y: root.u(14)
                                width: root.u(150)
                                height: root.u(96)
                                color: Tokens.color.lightYellow
                            }
                            PopupFrame {
                                anchors.fill: parent
                                title: Strings.settings.title
                                subtitle: Strings.settings.subtitle
                                footerLeft: Strings.settings.version
                                keys: page2.keysCategories
                            }
                        }
                    }
                }
            }

            Vignette {
                anchors.fill: parent
                s: root.s
                enabled: Settings.vignette
            }
        }
    }
}
