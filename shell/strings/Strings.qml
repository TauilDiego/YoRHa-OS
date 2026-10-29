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
        readonly property string grid: "Grid background"
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
        readonly property string page2Subtitle: "-Design System 2/2"
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
}
