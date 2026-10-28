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
        readonly property string version: "rien-OS 0.1 · Hyprland"
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
        readonly property string footer: "rien-OS 0.1 · %1"        // %1 = how many monitors
        readonly property string oneMonitor: "1 monitor"
        readonly property string manyMonitors: "%1 monitors"
    }
    // --- end spec 004 ----------------------------------------------------------------------------

    // --- spec 007: pause menu ---------------------------------------------------------------------
    readonly property PauseStrings pause: PauseStrings {}
    component PauseStrings: QtObject {
        // tabs: label, title and subtitle (the title row under the tab bar)
        readonly property var tabs: ({
            apps: { label: "APPS", title: "APPS", subtitle: "-Launcher" },
            windows: { label: "WINDOWS", title: "WINDOWS", subtitle: "-Open Windows" },
            system: { label: "SYSTEM", title: "SYSTEM", subtitle: "-Settings" },
            power: { label: "POWER", title: "POWER", subtitle: "-Session" }
        })
        // the footer's left text
        readonly property string appsFooter: "%1 apps · type to search"        // %1 = how many
        readonly property string windowsFooter: "%1 windows · %2 workspaces"
        readonly property string powerFooter: "Up %1"                          // %1 = uptime
        // key hints (the keys themselves are Strings.settings.key*)
        readonly property string keyTab: "Tab"
        readonly property string nextTab: "Next tab"
        readonly property string open: "Open"
        readonly property string options: "Options"
        readonly property string clear: "Clear"
        readonly property string focus: "Focus"
        readonly property string actions: "Actions"
        readonly property string confirm: "Confirm"
        readonly property string cancel: "Cancel"
        // APPS: groups, search, preview, options, info
        readonly property string pinned: "PINNED"
        readonly property string allApps: "ALL APPS"
        readonly property string search: "SEARCH"
        readonly property string results: "%1 RESULTS"
        readonly property string oneResult: "1 RESULT"
        readonly property string noMatch: "No apps match."
        readonly property string noMatchTitle: "No match"
        readonly property string noMatchText: "Check the spelling, or search by what the app does."
        readonly property string opened: "Opened: %1 times"
        readonly property string openedOnce: "Opened: once"
        readonly property string neverOpened: "Not opened yet"
        readonly property string appOptions: "Options"
        readonly property string workspace: "Workspace"
        readonly property string current: "Current"
        readonly property string pinnedOption: "Pinned"
        readonly property string category: "Category"
        readonly property string command: "Command"
        readonly property string windows: "Windows"
        readonly property string inTerminal: "%1 · in a terminal"
        readonly property string none: "—"
        readonly property var categories: ({
            System: "System", Network: "Network", Media: "Media", Office: "Office",
            Development: "Development", Graphics: "Graphics", Game: "Game", Other: "Other"
        })
        // WINDOWS
        readonly property string workspaceN: "WORKSPACE %1"
        readonly property string special: "SPECIAL"
        readonly property string groupNote: "%1 · %2"                          // monitor · count
        readonly property string focusedMark: "●"
        readonly property string noWindows: "No open windows."
        readonly property string noWindowsText: "No open windows. Open an app in APPS."
        readonly property string windowActions: "Actions"
        readonly property string floating: "Floating"
        readonly property string close: "Close"
        readonly property string go: "Go"
        readonly property string app: "App"
        readonly property string monitor: "Monitor"
        readonly property string size: "Size"
        readonly property string sizeValue: "%1 × %2"
        readonly property string tiled: "Tiled"
        readonly property string floatingState: "Floating"
        readonly property string windowFoot: "%1 · %2"                         // Tiled · 1280 × 720
        readonly property string mapEmpty: "Empty"
        // POWER: the actions, what they do, what happens now, why one is off, the dialog
        readonly property var powerLabels: ({
            lock: "Lock", logout: "Log out", suspend: "Suspend",
            hibernate: "Hibernate", reboot: "Reboot", poweroff: "Shut down"
        })
        readonly property var powerTexts: ({
            lock: "Locks the screen. Your apps keep running, and your password unlocks it.",
            logout: "Ends the session and goes back to the login screen.",
            suspend: "Keeps the session in memory and sleeps. A key or opening the lid wakes it.",
            hibernate: "Saves the session to disk and turns the computer off.",
            reboot: "Closes every app and starts the computer again.",
            poweroff: "Closes every app and turns the computer off."
        })
        readonly property string windowsWillClose: "%1 open windows will close."
        readonly property string oneWindowWillClose: "1 open window will close."
        readonly property string noWindowWillClose: "No open window will close."
        readonly property string sessionStays: "The session stays as it is."
        readonly property string unsavedMayAsk: "Apps with unsaved work may ask first."
        readonly property string notSupported: "Not supported on this machine."
        readonly property string notAllowed: "Not allowed."
        readonly property string holding: "%1: %2"                             // who: why
        readonly property string dialogTitle: "%1?"                            // Shut down?
        readonly property string confirmation: "Confirmation"
        readonly property string asked: "Asked"
        readonly property string noneAsked: "None"
        readonly property string now: "Now"
        readonly property string available: "Available"
        readonly property string unavailable: "Unavailable"
        readonly property string refused: "The system refused: %1"
        readonly property string lastRefused: "Last time, the system refused %1: %2"
        readonly property string running: "Asking the system…"
        // the status card
        readonly property string status: "Status"
        readonly property string user: "USER"
        readonly property string host: "HOST"
        readonly property string uptime: "UPTIME"
        readonly property string battery: "BATTERY"
        readonly property string windowsCount: "WINDOWS"
        readonly property string noError: "NO ERROR"
        readonly property string noBattery: "—"
        readonly property string uptimeHM: "%1h %2m"
        readonly property string uptimeM: "%1m"
        readonly property string uptimeD: "%1d %2h"
        readonly property string charging: "%1% +"
        readonly property string percent: "%1%"
        // short errors when a tab's test data is missing or broken (the card says it; the log says why)
        readonly property string appsError: "App data unavailable."
        readonly property string windowsError: "Window data unavailable."
        readonly property string sessionError: "Session data unavailable."
    }
    // --- end spec 007 -----------------------------------------------------------------------------
}
