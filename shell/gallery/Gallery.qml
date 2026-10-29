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
import "../wallpaper"

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

    // spec 004: a miniature 16:9 screen with a hairline frame (page 3).
    component Tile: Item {
        default property alias content: tileBody.data
        width: root.u(270)
        height: root.u(152)
        Item {
            id: tileBody
            anchors.fill: parent
            clip: true
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: Tokens.line(1, root.s)
            border.color: Tokens.color.darkGray
        }
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
        Keys.onTabPressed: root.page = (root.page + 1) % 4     // spec 003: page 2; 004: page 3; 007: page 4

        Rectangle {
            anchors.fill: parent
            color: Tokens.color.darkYellow
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
                        name: Strings.gallery.paper
                        height: root.u(100)
                        // The desktop background in miniature: paper, arcs, beams and vignette.
                        Item {
                            width: Math.round(height * 16 / 9)
                            height: parent.height
                            clip: true
                            Rectangle {
                                anchors.fill: parent
                                color: Tokens.color.darkYellow
                            }
                            PaperDecor {
                                anchors.fill: parent
                                s: parent.height / 1080
                            }
                            Vignette {
                                anchors.fill: parent
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

        // --- spec 004: page 3 (Tab), the wallpaper pieces (FR-022) -----------------------------------
        // Loaded only while shown: the scenes, the paper filter, a still frame of each transition, the
        // grouped list and the list + preview + options layout of the picker, in miniature.
        Loader {
            anchors.fill: parent
            active: root.page === 2
            sourceComponent: page3
        }

        // --- spec 007: page 4 (Tab), the pause menu's pieces, loaded only while shown -------------
        Loader {
            anchors.fill: parent
            active: root.page === 3
            sourceComponent: page4
        }
    }

    Component {
        id: page3

        Rectangle {
            id: p3
            color: Tokens.color.darkYellow

            // QsWindow.window is typed QObject: go through a var (as Rule does) to read its screen.
            readonly property var window: QsWindow.window
            readonly property real dpr: Tokens.scaleOf(window?.screen?.name ?? "")
            readonly property var ws: Strings.wallpaper
            readonly property var scenes: WallpaperCatalog.items.filter(w => w.type === "scene")
            readonly property string picturePath: Quickshell.shellPath("fixtures/wallpapers/ruins.jpg")
            readonly property var picture: ({
                id: "image:" + picturePath,
                type: "image",
                name: "ruins.jpg",
                url: WallpaperCatalog.fileUrl(picturePath),
                path: picturePath
            })
            // [kind, ms held at, when]: camouflage at 700 ms; the others halfway (450 of 900 ms).
            readonly property var frames: [
                ["camouflage", 700, Strings.gallery.camouflageAt], ["wipe", 450, Strings.gallery.halfway],
                ["tiles", 450, Strings.gallery.halfway], ["crossfade", 450, Strings.gallery.halfway]
            ]
            readonly property var listSample: [
                { group: ws.scenes }, { label: scenes[0]?.name ?? "", trailing: ws.mark + " " + ws.all }, { label: scenes[2]?.name ?? "" },
                { group: ws.video }, { label: ws.videoName, dim: true }
            ]

            PageHeader {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(Tokens.space.pageMarginV)
                s: root.s
                title: Strings.gallery.title
                subtitle: Strings.gallery.page3Subtitle
            }

            Rule {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(128)
                width: parent.width - 2 * x
                s: root.s
            }

            // --- column 1: the four scenes
            Section {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(root.bodyY)
                name: Strings.gallery.scenes

                Grid {
                    columns: 2
                    columnSpacing: root.u(20)
                    rowSpacing: root.u(14)
                    Repeater {
                        model: p3.scenes
                        Column {
                            id: sceneTile
                            required property var modelData
                            spacing: root.u(8)
                            Tile {
                                WallpaperView {
                                    anchors.fill: parent
                                    wallpaper: sceneTile.modelData
                                    s: height / 1080
                                }
                            }
                            Caption { text: sceneTile.modelData.name }
                        }
                    }
                }
            }

            // --- column 2: a still frame of each transition, from "Menu" to "Dark"
            Section {
                x: root.u(Tokens.space.pageMarginH + root.colW + root.colGap)
                y: root.u(root.bodyY)
                name: Strings.gallery.transitions

                Grid {
                    columns: 2
                    columnSpacing: root.u(20)
                    rowSpacing: root.u(14)
                    Repeater {
                        model: p3.frames
                        Column {
                            id: frameTile
                            required property var modelData
                            spacing: root.u(8)
                            Tile {
                                WallpaperTransition {
                                    id: still
                                    property bool held: false
                                    anchors.fill: parent
                                    current: "scene:menu"
                                    s: height / 1080
                                    dpr: p3.dpr
                                    kind: frameTile.modelData[0]
                                    instant: false
                                    Component.onCompleted: Qt.callLater(() => still.current = "scene:dark")
                                    onAnimatingChanged: {
                                        if (animating && !held) {
                                            held = true;
                                            Qt.callLater(() => still.hold(frameTile.modelData[1]));
                                        }
                                    }
                                }
                            }
                            Caption {
                                text: Strings.gallery.frameAt.arg(p3.ws.transitionLabels[frameTile.modelData[0]]).arg(frameTile.modelData[2])
                            }
                        }
                    }
                }
            }

            // --- column 3: a picture with and without the paper filter
            Column {
                x: root.u(Tokens.space.pageMarginH + 2 * (root.colW + root.colGap))
                y: root.u(root.bodyY)
                spacing: root.u(root.sectionGap)

                Section {
                    name: Strings.gallery.paperFilter
                    Row {
                        spacing: root.u(20)
                        Repeater {
                            model: [true, false]
                            Column {
                                id: filterTile
                                required property bool modelData
                                spacing: root.u(8)
                                Tile {
                                    WallpaperView {
                                        anchors.fill: parent
                                        wallpaper: p3.picture
                                        s: height / 1080
                                        screenSize: Qt.size(Math.round(width * p3.dpr), Math.round(height * p3.dpr))
                                        paperFilter: filterTile.modelData
                                    }
                                }
                                Caption {
                                    text: Strings.gallery.frameAt.arg(Strings.gallery.paperFilter).arg(filterTile.modelData ? Strings.gallery.filterOn : Strings.gallery.filterOff)
                                }
                            }
                        }
                    }
                }
            }

            // --- bottom right: the grouped list, with and without the focus
            Section {
                x: root.u(840)
                y: root.u(600)
                name: Strings.gallery.groupedList
                Row {
                    spacing: root.u(40)
                    Repeater {
                        model: [true, false]
                        Column {
                            id: listCol
                            required property bool modelData
                            spacing: root.u(8)
                            GroupedList {
                                width: root.u(470)
                                height: implicitHeight
                                s: root.s
                                keysEnabled: false
                                focused: listCol.modelData
                                model: p3.listSample
                                currentIndex: 0
                            }
                            Caption {
                                text: listCol.modelData ? Strings.gallery.stateFocused : Strings.gallery.groupedListUnfocused
                            }
                        }
                    }
                }
            }

            // --- bottom: the list + preview + options layout, in a pop-up frame over the menu scene
            Section {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(600)
                name: Strings.gallery.pickerLayout

                Item {
                    width: root.u(720)
                    height: root.u(405)
                    clip: true
                    WallpaperView {
                        anchors.fill: parent
                        wallpaper: WallpaperCatalog.byId("scene:menu")
                        s: height / 1080
                    }
                    PopupFrame {
                        id: miniFrame
                        anchors.fill: parent
                        title: p3.ws.title
                        subtitle: p3.ws.subtitle
                        footerLeft: p3.ws.footer.arg(p3.ws.oneMonitor)
                        keys: miniLayout.keys

                        PickerLayout {
                            id: miniLayout
                            anchors.fill: parent
                            s: miniFrame.s
                            entries: [{ group: p3.ws.scenes }].concat(p3.scenes.map((w, i) => ({
                                label: w.name, trailing: i === 0 ? p3.ws.mark + " " + p3.ws.all : ""
                            })), [{ group: p3.ws.video }, { label: p3.ws.videoName, dim: true }])
                            index: 2
                            options: [
                                { id: "monitor", label: p3.ws.monitor, values: [p3.ws.allMonitors] },
                                { id: "transition", label: p3.ws.transition, values: Settings.transitionKinds.map(k => p3.ws.transitionLabels[k]) }
                            ]
                            values: ({ monitor: 0, transition: 0 })
                            info: [
                                { label: p3.ws.type, value: p3.ws.typeLabels.scene },
                                { label: p3.ws.motion, value: p3.ws.motionSlow }
                            ]

                            PreviewCard {
                                width: miniLayout.previewWidth
                                s: miniFrame.s
                                wallpaper: p3.scenes[2] ?? null
                                dpr: p3.dpr
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

    // --- spec 007: page 4 (Tab), the pause menu's pieces (FR-033) ---------------------------------
    // Loaded only while shown: the tabbed frame (each tab selected, one hovered), the search header
    // and the empty search, the app icon in its three styles (a fixture icon and none: the generic
    // one), the workspace map (empty, with windows, with the chosen one), the status card (NO ERROR
    // and a note) and the confirm dialog (the kite on Cancel and on the action), in miniature.
    Component {
        id: page4

        Rectangle {
            id: p4
            color: Tokens.color.darkYellow

            readonly property var ps: Strings.pause
            readonly property var tabs: ["apps", "windows", "system", "power"].map(t => ({ label: ps.tabs[t].label }))
            readonly property string iconPath: Quickshell.shellPath("fixtures/pause/icons/terminal.svg")
            readonly property string genericPath: Quickshell.shellPath("assets/icons/category-system.svg")
            readonly property var monitor: ({ name: "Virtual-1", w: 1920, h: 1080 })
            readonly property var mapWindows: [
                { address: "0x1", x: 0, y: 40, w: 956, h: 1040, title: "kitty", focused: false },
                { address: "0x2", x: 964, y: 40, w: 956, h: 516, title: "Firefox", focused: true },
                { address: "0x3", x: 964, y: 564, w: 956, h: 516, title: "btop", focused: false }
            ]
            readonly property var statusRows: [
                { label: ps.user, value: "arch", meter: null },
                { label: ps.host, value: "nier-lab", meter: null },
                { label: ps.uptime, value: ps.uptimeHM.arg(2).arg(14), meter: null },
                { label: ps.battery, value: ps.percent.arg(87), meter: 0.87 },
                { label: ps.windowsCount, value: "7", meter: null }
            ]
            // The page must fit 16:10 too (s = height / 1080 leaves 1728 game px of width there):
            // a narrower dialog column, and the third one ends by 1666 (where the header's rule ends).
            readonly property real dialogW: 430
            readonly property real col2: Tokens.space.pageMarginH + root.colW + root.colGap
            readonly property real col3: col2 + dialogW + 60

            PageHeader {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(Tokens.space.pageMarginV)
                s: root.s
                title: Strings.gallery.title
                subtitle: Strings.gallery.page4Subtitle
            }

            Rule {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(128)
                width: parent.width - 2 * x
                s: root.s
            }

            // --- column 1: the tabbed frame, then the search header and the empty search
            Column {
                x: root.u(Tokens.space.pageMarginH)
                y: root.u(root.bodyY)
                spacing: root.u(root.sectionGap)

                Section {
                    name: Strings.gallery.tabbedFrame
                    Grid {
                        columns: 2
                        columnSpacing: root.u(20)
                        rowSpacing: root.u(14)
                        Repeater {
                            model: 4
                            Column {
                                id: frameTile
                                required property int index
                                spacing: root.u(8)
                                Tile {
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Tokens.color.darkYellow
                                    }
                                    PopupFrame {
                                        anchors.fill: parent
                                        tabs: p4.tabs
                                        tab: frameTile.index
                                        hoveredTab: frameTile.index === 0 ? 1 : -1
                                        clock: true
                                        title: p4.ps.tabs[["apps", "windows", "system", "power"][frameTile.index]].title
                                        subtitle: p4.ps.tabs[["apps", "windows", "system", "power"][frameTile.index]].subtitle
                                    }
                                }
                                Caption {
                                    text: frameTile.index === 0
                                        ? Strings.gallery.frameAt.arg(p4.tabs[0].label).arg(Strings.gallery.tabHovered.arg(p4.tabs[1].label))
                                        : p4.tabs[frameTile.index].label
                                }
                            }
                        }
                    }
                }

                Section {
                    name: Strings.gallery.searchHeader
                    Column {
                        spacing: root.u(14)
                        SearchHeader {
                            s: root.s
                            query: "fir"
                            count: 3
                        }
                        GroupedList {
                            width: root.u(470)
                            height: implicitHeight
                            s: root.s
                            keysEnabled: false
                            search: ({ query: "zzz", count: 0 })
                            emptyText: p4.ps.noMatch
                            model: []
                        }
                    }
                }
            }

            // --- column 2: the confirm dialog, the kite on Cancel and on the action
            Section {
                x: root.u(p4.col2)
                y: root.u(root.bodyY)
                name: Strings.gallery.confirmDialog

                Column {
                    spacing: root.u(14)
                    Repeater {
                        model: ["cancel", "action"]
                        Column {
                            id: dialogTile
                            required property string modelData
                            spacing: root.u(8)
                            Item {
                                width: root.u(p4.dialogW)
                                height: root.u(240)
                                clip: true
                                Rectangle {
                                    anchors.fill: parent
                                    color: Tokens.color.lightYellow
                                }
                                ConfirmDialog {
                                    anchors.fill: parent
                                    enabled: false
                                    s: root.s * 0.5
                                    start: dialogTile.modelData
                                    title: p4.ps.dialogTitle.arg(p4.ps.powerLabels.poweroff)
                                    text: p4.ps.windowsWillClose.arg(7)
                                    blockers: [{ who: "pacman", why: "System update in progress" }]
                                    actionLabel: p4.ps.powerLabels.poweroff
                                }
                            }
                            Caption {
                                text: Strings.gallery.kiteOn.arg(dialogTile.modelData === "cancel" ? p4.ps.cancel : p4.ps.powerLabels.poweroff)
                            }
                        }
                    }
                }
            }

            // --- column 3: the app icon, the workspace map, the status card
            Column {
                x: root.u(p4.col3)
                y: root.u(root.bodyY)
                spacing: root.u(root.sectionGap)

                Section {
                    name: Strings.gallery.appIcon
                    Grid {
                        columns: 3
                        columnSpacing: root.u(40)
                        rowSpacing: root.u(10)
                        flow: Grid.TopToBottom
                        rows: 2
                        Repeater {
                            model: ["ink", "ink", "color", "color", "square", "square"]
                            Column {
                                id: iconCell
                                required property string modelData
                                required property int index
                                readonly property bool generic: index % 2 === 1
                                spacing: root.u(6)
                                Rectangle {
                                    width: root.u(84)
                                    height: root.u(84)
                                    color: Tokens.color.lightGray
                                    AppIcon {
                                        anchors.centerIn: parent
                                        s: root.s
                                        size: 64
                                        style: iconCell.modelData
                                        source: iconCell.generic ? "" : p4.iconPath
                                        fallback: p4.genericPath
                                    }
                                }
                                Caption {
                                    text: iconCell.generic ? Strings.gallery.frameAt.arg(iconCell.modelData).arg(Strings.gallery.genericIcon) : iconCell.modelData
                                }
                            }
                        }
                    }
                }

                Section {
                    name: Strings.gallery.workspaceMap
                    Row {
                        spacing: root.u(14)
                        Repeater {
                            model: [Strings.gallery.mapEmpty, Strings.gallery.mapWindows, Strings.gallery.mapChosen]
                            Column {
                                id: mapCell
                                required property string modelData
                                required property int index
                                spacing: root.u(6)
                                WorkspaceMap {
                                    width: implicitWidth
                                    height: implicitHeight
                                    s: root.s * 0.3
                                    monitor: p4.monitor
                                    bar: 40
                                    windows: mapCell.index === 0 ? [] : p4.mapWindows
                                    selected: mapCell.index === 2 ? "0x2" : ""
                                }
                                Caption { text: mapCell.modelData }
                            }
                        }
                    }
                }

                Section {
                    name: Strings.gallery.statusCard
                    Row {
                        spacing: root.u(20)
                        Repeater {
                            model: ["", Strings.gallery.statusNote]
                            StatusCard {
                                required property string modelData
                                width: implicitWidth
                                height: implicitHeight
                                s: root.s * 0.58
                                rows: p4.statusRows
                                note: modelData
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
