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
    readonly property string brand: "rien-OS"
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
    }
}
