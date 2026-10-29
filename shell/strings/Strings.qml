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
        readonly property string page2Subtitle: "-Design System 2/5"
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
        readonly property string page3Subtitle: "-Design System 3/5"
        // spec 008: transmissions, the OSD and the text log (pages 4 and 5)
        readonly property string page4Subtitle: "-Design System 4/5"
        readonly property string page5Subtitle: "-Design System 5/5"
        readonly property string band: "Band"
        readonly property string overPaper: "over paper"
        readonly property string overDark: "over the dark scene"
        readonly property string transmission: "Transmission"
        readonly property string typingHalf: "typing (still at 50%)"
        readonly property string withActions: "with actions"
        readonly property string withReply: "with image, reply open"
        readonly property string withProgress: "with progress, low"
        readonly property string grouped: "grouped ×5"
        readonly property string criticalBand: "Critical band"
        readonly property string osd: "OSD"
        readonly property string positions: "Positions"
        readonly property string counter: "Bar counter"
        readonly property string logPopup: "Text log · pop-up body"
        readonly property string logPause: "Text log · pause-menu body"
        readonly property string actionButton: "Action button"
        readonly property string tags: "Tags"
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

    // --- spec 008: transmissions, the text log, the OSD, the Notifications options ---------------
    readonly property NotifyStrings notify: NotifyStrings {}
    component NotifyStrings: QtObject {
        // the text log
        readonly property string title: "LOG"
        readonly property string subtitle: "-Transmissions"
        readonly property string footer: "YoRHa-OS 0.1 · notification server"
        readonly property string now: "NOW"
        readonly property string earlier: "EARLIER"
        readonly property string newTag: "NEW"
        readonly property string critical: "CRITICAL"
        readonly property string transmission: "Transmission"
        readonly property string options: "Options"
        readonly property string overflow: "+%1 in log"          // %1 = unread ones that left early
        readonly property string moreInLog: "More in log"
        readonly property string reply: "Reply"
        readonly property string send: "Enter Send"
        readonly property string cancel: "Esc Cancel"
        readonly property string unknown: "Unknown"
        readonly property string count: "×%1"                    // a grouped transmission
        readonly property string page: "%1/%2"                   // the critical band's pages
        readonly property string close: "×"
        // the preview's notes
        readonly property string closedNote: "The app closed this notification."
        readonly property string earlierNote: "From an earlier session."
        readonly property string answeredNote: "Answered: %1"
        readonly property string emptyTitle: "No transmissions."
        readonly property string emptyText: "Nothing here yet. New transmissions land here."
        // the log's options and information
        readonly property string dnd: "Do not disturb"
        readonly property string show: "Show"
        readonly property string showAll: "All"
        readonly property string showUnread: "Unread"
        readonly property string showCritical: "Critical"
        readonly property string clearAll: "Clear all"
        readonly property string clear: "Clear"
        readonly property string on: "On"
        readonly property string off: "Off"
        readonly property string unread: "Unread"
        readonly property string kept: "Kept"
        readonly property string keptOf: "%1 / %2"
        readonly property string server: "Server"
        readonly property string serverOn: "Running"
        readonly property string serverOff: "Unavailable"
        readonly property string app: "App"
        readonly property string received: "Received"
        readonly property string urgency: "Urgency"
        readonly property string status: "Status"
        readonly property var urgencyLabels: ({ low: "Low", normal: "Normal", critical: "Critical" })
        readonly property string statusWaiting: "Waiting"
        readonly property string statusAnswered: "Answered"
        readonly property string statusClosed: "Closed"
        readonly property string statusEarlier: "Earlier session"
        readonly property string dateFormat: "yyyy.MM.dd HH:mm"
        readonly property string timeFormat: "HH:mm"
        // key hints
        readonly property string keyDelete: "Del"
        readonly property string keyAction: "Action"
        readonly property string keyDismiss: "Dismiss"
        readonly property string keyOptions: "Options"
        readonly property string keySelect: "Select"
        readonly property string keyChange: "Change"
        readonly property string keyBack: "Back"
        readonly property string keyClose: "Close"
        // the OSD
        readonly property string volume: "VOLUME"
        readonly property string mute: "MUTE"
        readonly property string micOn: "MIC ON"
        readonly property string micOff: "MIC OFF"
        readonly property string brightness: "BRIGHTNESS"
        // the top bar's counter
        readonly property string counterLog: "LOG"
        readonly property string counterDnd: "DND"
        // the system's voice (FR-003)
        readonly property var voices: ({ relay: "Relay 01", yorhaos: "YoRHa-OS", system: "System" })
        readonly property string serverMissing: "Notification server unavailable"
        readonly property string serverMissingText: "Another program owns the notification name (%1). Transmissions stay off until it quits."
        // the Notifications category of the settings (FR-039, FR-042)
        readonly property string category: "Notifications"
        readonly property string categoryAbout: "How transmissions, the text log and the on-screen display behave. These options apply at once and are kept."
        readonly property var prefLabels: ({
            dnd: "Do not disturb", position: "Position", osdPosition: "OSD position", voice: "System voice",
            log: "Text log", logSize: "Log size", monitor: "Monitor", onScreen: "On screen",
            duration: "Duration", typing: "Typing", fullscreen: "In fullscreen"
        })
        readonly property var prefValues: ({
            position: ["Corner", "Top band", "Subtitle"],
            osdPosition: ["Bottom", "Top"],
            voice: ["Relay 01", "YoRHa-OS", "System"],
            log: ["Session only", "Saved"],
            logSize: ["100", "50", "200"],
            monitor: ["Focused"],
            onScreen: ["3", "1", "5"],
            duration: ["Normal", "Short", "Long"],
            fullscreen: ["Hold", "Show"]
        })
        readonly property var prefDescs: ({
            dnd: "Keeps transmissions off the screen. Critical ones still show, and everything waits in the text log. The top bar shows DND and the unread count. Default: Off.",
            position: "Where transmissions appear. Corner: under the top bar, on the right. Top band: full-width bands under the bar. Subtitle: centered at the bottom, like the Pod's lines. Default: Corner.",
            osdPosition: "Where the volume, microphone and brightness display appears: centered at the bottom, or under the top bar. Default: Bottom.",
            voice: "The name YoRHa-OS speaks with in its own messages. Apps keep their own names. Default: Relay 01.",
            log: "Session only keeps the text log in memory until you log out. Saved also writes the last messages to disk, readable only by you; going back to Session only deletes that file. Default: Session only.",
            logSize: "How many transmissions the text log keeps. The oldest go first. Default: 100.",
            monitor: "Where transmissions appear: the focused monitor when they arrive, or always the same one. Default: Focused.",
            onScreen: "How many transmissions show at once. When one more arrives, the oldest moves to the text log. Default: 3.",
            duration: "How long transmissions stay on screen, unless the app asks for a time. Short is two thirds; Long is half again. Default: Normal.",
            typing: "Types the text in, as the Pod speaks. Off shows it whole at once. Default: On.",
            fullscreen: "With a full-screen window in focus, Hold keeps transmissions in the text log, as do not disturb does; Show lets them through. Default: Hold."
        })
        // the samples the injector sends through the real path (FR-032, mockup)
        readonly property var samples: ({
            normal: { app: "Firefox", title: "Download finished", body: "archlinux-2026.10.01-x86_64.iso is in Downloads." },
            actions: { app: "Calendar", title: "Stand-up in 10 minutes", body: "Daily sync · Room 2 and online.", actions: [["open", "Open"], ["later", "Snooze"]] },
            reply: { app: "Chat", title: "Mika", body: "Are you still coming tonight? I saved you a seat by the window." },
            critical: { app: "Battery", title: "Battery at 5%", body: "Plug in the charger. The system suspends at 3%." },
            flood: { app: "Mail", title: "New message", body: "Message %1 of 5." },
            long: { app: "Build", title: "The nightly build finished with warnings in three packages and one test that took longer than usual", body: "Packages: quickshell, hyprland, yorha-shell. The slow test was settings/persist, at 4.2 s against 1.1 s yesterday. Nothing failed, but the warnings repeat the same deprecation notice about the old layer-shell namespace, which the next release removes. The full log is in ~/builds/nightly.log, and a summary was mailed to you. Run yorha build --verbose to see every step again." },
            progress: { app: "Downloads", title: "archlinux.iso", body: "Downloading…", value: 40 },
            low: { app: "Updates", title: "3 updates available", body: "They install the next time you restart." },
            script: { app: "script.sh", title: "Step %1 of 100", body: "Job %1 finished." },
            system: { title: "Welcome back", body: "Transmissions are on. The text log keeps what you missed." }
        })
    }
    // --- end spec 008 ----------------------------------------------------------------------------
}
