pragma Singleton

import QtQuick
import Quickshell

// Every fixed UI text, in English like the game (FR-018). Kept in one place for future i18n.
Singleton {
    readonly property string cpu: "CPU"
    readonly property string mem: "MEM"
    readonly property string vol: "VOL"
    readonly property string bat: "BAT"
    readonly property string system: "SYSTEM"
    readonly property string brand: "YoRHa-OS"
    readonly property string charging: "+"         // after the battery percent while charging
    readonly property string muted: "MUTE"         // in place of the volume percent

    readonly property GalleryStrings gallery: GalleryStrings {}
    component GalleryStrings: QtObject {
        readonly property string title: "SYSTEM"
        readonly property string subtitle: "-Design System"
        readonly property string primitives: "Primitives"
        readonly property string square: "Square"
        readonly property string rules: "Rules"
        readonly property string rulePlain: "plain"
        readonly property string ruleDotted: "dotted"
        readonly property string ruleVertical: "vertical"
        readonly property string paper: "Paper"
        readonly property string headerButton: "Header button"
        readonly property string listItem: "List item"
        readonly property string selector: "Selector"
        readonly property string selectorDark: "dark"
        readonly property string selectorLight: "light"
        readonly property string meter: "Meter"
        readonly property string meterNormal: "normal"
        readonly property string meterCritical: "critical"
        readonly property string pageHeader: "Page header"
        readonly property string card: "Card"
        readonly property string cardTitle: "Status"
        readonly property string cardBody: "No error."
        readonly property string tabBar: "Tab bar"
        readonly property string cursorList: "Cursor list"
        readonly property string stateNormal: "normal"
        readonly property string stateHovered: "hovered"
        readonly property string stateSelected: "selected"
        readonly property string stateDimmed: "dimmed"
        readonly property string sampleItem: "Recovery"
        readonly property var sampleList: ["Recovery", "Enhancements", "Support", "Materials", "Key Items"]
        readonly property var sampleTabs: ["MAP", "QUESTS", "ITEMS", "SYSTEM"]
        // Added by the gallery (T033).
        readonly property string squareInk: "ink"
        readonly property string squareLight: "light"
        readonly property string variantOpaque: "opaque"
        readonly property string variantPlain: "plain"
        readonly property string samplePageTitle: "Items"
        readonly property string samplePageSubtitle: "All Items"
        // spec 003: the settings pieces, on the gallery's second page (Tab)
        readonly property string page2Subtitle: "-Design System 2/3"
        readonly property string valueStepper: "Value stepper"
        readonly property string stepperMiddle: "middle"
        readonly property string stepperStart: "start"
        readonly property string stepperEnd: "end"
        readonly property string meterEditable: "editable"
        readonly property string meterInverted: "inverted"
        readonly property string keyHints: "Key hints"
        readonly property string optionRow: "Option row"
        readonly property string stateFocused: "focused"
        readonly property string descriptionCard: "Description card"
        readonly property string cardWithNote: "with note"
        readonly property string cursorListUnfocused: "Cursor list, unfocused"
        readonly property string popupFrame: "Pop-up frame"
        // spec 004: the wallpaper pieces, on the gallery's third page (Tab)
        readonly property string page3Subtitle: "-Design System 3/3"
        readonly property string scenes: "Scenes"
        readonly property string paperFilter: "Paper filter"
        readonly property string filterOn: "on"
        readonly property string filterOff: "off"
        readonly property string transitions: "Transitions"
        readonly property string groupedList: "Grouped list"
        readonly property string groupedListUnfocused: "unfocused"
        readonly property string pickerLayout: "List + preview + options"
        readonly property string frameAt: "%1 · %2"           // a transition's still frame: kind · when
        readonly property string camouflageAt: "700 ms"
        readonly property string halfway: "50%"
    }

    // --- spec 003: settings pop-up ---------------------------------------------------------
    readonly property SettingsStrings settings: SettingsStrings {}
    component SettingsStrings: QtObject {
        readonly property string title: "SYSTEM"
        readonly property string subtitle: "-Settings"
        readonly property string categories: "CATEGORIES"
        readonly property string count: "SETTINGS"        // "5 SETTINGS" and the card's SETTINGS row
        readonly property string defaultLabel: "DEFAULT"
        readonly property string nowLabel: "NOW"
        readonly property string on: "ON"
        readonly property string off: "OFF"
        readonly property string version: "YoRHa-OS 0.1 · Hyprland"
        readonly property string error: "Settings data unavailable."
        // key hints: the key, then what it does
        readonly property string keyUpDown: "↑↓"
        readonly property string keyRight: "→"
        readonly property string keyLeftRight: "←→"
        readonly property string keyEnter: "Enter"
        readonly property string keyEsc: "Esc"
        readonly property string select: "Select"
        readonly property string open: "Open"
        readonly property string close: "Close"
        readonly property string change: "Change"
        readonly property string back: "Back"
    }

    // --- spec 004: wallpaper (picker, catalog, transitions) --------------------------------------
    readonly property WallpaperStrings wallpaper: WallpaperStrings {}
    component WallpaperStrings: QtObject {
        readonly property string title: "WALLPAPER"
        readonly property string subtitle: "-Select"
        // list groups
        readonly property string scenes: "SCENES"
        readonly property string images: "IMAGES"
        readonly property string video: "VIDEO"
        // options card
        readonly property string options: "Options"
        readonly property string monitor: "Monitor"
        readonly property string allMonitors: "All monitors"
        readonly property string transition: "Transition"
        readonly property var transitionLabels: ({ camouflage: "Camouflage", wipe: "Wipe", tiles: "Tiles", crossfade: "Crossfade" })
        readonly property string paperFilter: "Paper filter"
        readonly property string on: "On"
        readonly property string off: "Off"
        // information
        readonly property string type: "Type"
        readonly property string layers: "Layers"
        readonly property string motion: "Motion"
        readonly property string nowOn: "Now on"
        readonly property string all: "ALL"
        readonly property string none: "—"
        readonly property var typeLabels: ({ scene: "Scene", image: "Image", video: "Video" })
        readonly property string layerPaper: "Paper · Vignette"
        readonly property string layerDark: "Dark paper"
        readonly property string layerPicture: "Picture · Paper filter"
        readonly property string layerPictureRaw: "Picture"
        readonly property string layerArcs: "Arcs"
        readonly property string layerBeams: "Beams"
        readonly property string layerRules: "Rules"
        readonly property string motionSlow: "Slow"
        readonly property string motionNone: "None"
        // key hints
        readonly property string keySelect: "Select"
        readonly property string keyApply: "Apply"
        readonly property string keyOptions: "Options"
        readonly property string keyChange: "Change"
        readonly property string keyBack: "Back"
        readonly property string keyClose: "Close"
        // catalog entries without a JSON of their own
        readonly property string videoName: "Videos"
        readonly property string videoText: "Video wallpapers come later, once the optimization phase (U6) measures what they cost."
        readonly property string notYet: "NOT YET"
        readonly property string imageText: "A picture from your wallpaper folder. The paper filter pulls its colors toward the paper and adds the vignette; turn it off to see the picture as it is."
        // %1 = the folder
        readonly property string emptyFolder: "Put pictures in %1"
        // the picker (US2): the applied mark in the list, joins, the footer
        readonly property string mark: "●"
        readonly property string separator: " · "
        readonly property string listSeparator: ", "
        readonly property string footer: "YoRHa-OS 0.1 · %1"        // %1 = how many monitors
        readonly property string oneMonitor: "1 monitor"
        readonly property string manyMonitors: "%1 monitors"
    }
    // --- end spec 004 ----------------------------------------------------------------------------
}
