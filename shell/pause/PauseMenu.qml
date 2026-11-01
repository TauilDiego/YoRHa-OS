pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../popup"
import "../services"
import "../settings"
import "../strings"

// The pause menu (spec 007, U3): the pop-up frame of spec 003 with the game's tab bar and one page
// per tab: APPS (launcher), WINDOWS, SYSTEM (the settings page of spec 003) and POWER. shell.qml
// opens it on the focused monitor, in the tab it asks for, and unloads it after closing (two
// steps, like every pop-up).
// Tabs (research R15) are data: an entry here and a page are all a new tab needs (spec 008's LOG
// goes after WINDOWS). Tab and Shift+Tab (Backtab) go round them; a click on a tab opens it; tabs
// never take the kite nor a keyboard focus of their own (FR-004). Each page keeps its cursor while
// the menu is open; a fresh menu starts each page by its opening rule (FR-006).
// Keys the page doesn't use reach this scope: Tab/Backtab switch, and on APPS any printable text
// goes to its search (R13). Escape on a page's first column closes (the page decides).
PopupWindow {
    id: root

    property string tab: "apps"
    property int systemCategory: 0               // where SYSTEM opens (shell.qml keeps it)
    // spec 013 (data-model.md, `pause dump`): the animation running, "idle" | "opening" |
    // "assembling" | "tab" | "closing" (front A sets it); the choice pop-up's state or null (front C).
    property string anim: popupFrame.anim        // front A
    property var choice: null
    // spec 013 (research R7): while countFrames, every frame's time (ms) goes out in frame().
    property bool countFrames: false

    signal closeRequested()
    signal frame(real ms)

    readonly property var tabList: [
        { id: "apps" },
        { id: "windows" },
        { id: "system" },
        { id: "power" }
    ]
    readonly property var tabIds: tabList.map(t => t.id)
    readonly property int tabIndex: Math.max(0, tabIds.indexOf(tab))
    readonly property var tabText: Strings.pause.tabs[tab] ?? Strings.pause.tabs.apps
    readonly property var page: pageOf(tab)

    function pageOf(id: string): var {
        switch (id) {
        case "apps":
            return appsPage;
        case "windows":
            return windowsPage;
        case "system":
            return systemPage;
        case "power":
            return powerPage;
        }
        return null;
    }

    // Open tab `id` (a click, `pause tab`, SUPER+I). The focus goes to the page's first column,
    // with its cursor where it was.
    function setTab(id: string): bool {
        if (!tabIds.includes(id))
            return false;
        if (id !== tab) {
            pageOf(tab)?.leave();
            tab = id;
        }
        pageOf(id)?.enter();
        Qt.callLater(root.focusPage);
        return true;
    }

    // Text that may go to APPS's search: something, and no control character in it (C0, DEL,
    // C1). Delete sends "\x7f", which is past " " and used to slip into the query.
    function printable(text: string): bool {
        return text.length > 0 && !/[\u0000-\u001f\u007f-\u009f]/.test(text);
    }

    function step(dir: int): void {
        setTab(tabIds[(tabIndex + dir + tabIds.length) % tabIds.length]);
    }

    function focusPage(): void {
        page?.forceActiveFocus();
    }

    // Tests only: APPS with `text` as its whole search.
    function search(text: string): void {
        setTab("apps");
        appsPage.setQuery(text);
    }

    // Every page back to its opening state (a reopened menu before it was unloaded, `pause reset`).
    function restart(): void {
        appsPage.restart();
        windowsPage.restart();
        systemPage.restart(systemCategory);
        powerPage.restart();
        pageOf(tab)?.enter();
        Qt.callLater(root.focusPage);
    }

    // SYSTEM's own state, in the format of spec 003's `settings dump` (shell.qml's alias).
    function systemDump(): var {
        return systemPage.dumpState();
    }

    function restartSystem(index: int): void {
        systemPage.restart(index);
    }

    // The footer's hints of a page, with "Tab Next tab" before Esc (SYSTEM adds its own).
    function withTab(keys: var): var {
        const t = { key: Strings.pause.keyTab, label: Strings.pause.nextTab };
        const last = keys[keys.length - 1];
        return last?.key === Strings.settings.keyEsc ? keys.slice(0, -1).concat([t, last]) : keys.concat([t]);
    }

    readonly property var pageKeys: tab === "system" ? systemPage.keys : withTab(page?.keys ?? [])

    // spec 013, front A (FR-006): while the tab changes, the old page stays shown and fades
    // (PopupFrame's swapFrom, swapLevel), and the new one waits hidden (swapHold) until it mounts.
    readonly property string fadingTab: tabIds[popupFrame.swapFrom] ?? ""
    function pageShown(id: string): bool {
        return tab === id || fadingTab === id;
    }
    function pageOpacity(id: string): real {
        return id === fadingTab ? popupFrame.swapLevel : popupFrame.swapHold ? 0 : 1;
    }
    // An action that leaves the menu (FR-008): the next close starts with the leaving row.
    function leaving(): void {
        leaveNext = true;
    }

    // spec 013 (research R7): the frame counter of `pause fps`, ticking with this window's frames.
    // The first tick after a start is dropped (its time runs from before the start).
    FrameAnimation {
        id: frames
        running: root.countFrames
        property bool first: true
        onRunningChanged: first = true
        onTriggered: {
            if (first)
                first = false;
            else
                root.frame(frameTime * 1000);
        }
    }

    // --- pause dump (contracts/ipc.md) -------------------------------------------------------------
    function dumpState(): var {
        const geo = page?.geometry?.() ?? null;
        return {
            open: keyboardActive,
            monitor: screen?.name ?? "",
            tab: tab,
            presentation: presentation,
            anim: anim,
            choice: choice,
            title: `${tabText.title} ${tabText.subtitle}`,
            footerLeft: footerLeft,
            keys: pageKeys.map(k => `${k.key} ${k.label}`),
            apps: appsPage.dumpState(),
            windows: windowsPage.dumpState(),
            system: (() => {
                const d = systemPage.dumpState();
                return { focus: d.focus, category: d.category, option: d.option };
            })(),
            power: powerPage.dumpState(),
            geometry: {
                s: Math.round(s * 1000) / 1000,
                panel: rectOf(panel),
                tabs: tabIds.map((t, i) => popupFrame.tabGeometry(i)),
                item: geo?.item ?? null,
                value: geo?.value ?? null
            }
        };
    }

    function rectOf(item: Item): var {
        const p = item.mapToItem(null, 0, 0);
        return { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(item.width), h: Math.round(item.height) };
    }

    tabs: tabList.map(t => ({ label: Strings.pause.tabs[t.id].label }))
    currentTab: tabIndex
    clock: true
    title: tabText.title
    subtitle: tabText.subtitle
    footerLeft: tab === "system" ? Strings.settings.version : (page?.footerLeft ?? "")
    keys: pageKeys
    onDismissed: closeRequested()
    onTabClicked: index => setTab(tabIds[index])
    // Reopened before it was unloaded: back to the opening rules, as a fresh one starts.
    onKeyboardActiveChanged: if (keyboardActive) restart()
    Component.onCompleted: {
        pageOf(tab)?.enter();
        Qt.callLater(root.focusPage);
    }

    FocusScope {
        id: keysRoot
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ControlModifier)) {
                root.step(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab) {
                root.step(-1);
                event.accepted = true;
            } else if (root.tab === "apps" && root.printable(event.text)
                       && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                appsPage.type(event.text);
                event.accepted = true;
            }
        }

        AppsPage {
            id: appsPage
            anchors.fill: parent
            visible: root.pageShown("apps")
            opacity: root.pageOpacity("apps")
            enabled: root.tab === "apps"
            s: root.s
            onLeaving: root.leaving()
            onCloseRequested: root.closeRequested()
        }

        WindowsPage {
            id: windowsPage
            anchors.fill: parent
            visible: root.pageShown("windows")
            opacity: root.pageOpacity("windows")
            enabled: root.tab === "windows"
            s: root.s
            onLeaving: root.leaving()
            onCloseRequested: root.closeRequested()
        }

        SettingsPage {
            id: systemPage
            anchors.fill: parent
            visible: root.pageShown("system")
            opacity: root.pageOpacity("system")
            enabled: root.tab === "system"
            s: root.s
            startY: Tokens.space.pauseBodyY + 34
            extraKeys: [{ key: Strings.pause.keyTab, label: Strings.pause.nextTab }]
            category: root.systemCategory
            onCategoryChanged: root.systemCategory = category
            onCloseRequested: root.closeRequested()

            function enter(): void {
            }
            function leave(): void {
            }
            function geometry(): var {
                return dumpState().geometry;
            }
        }

        PowerPage {
            id: powerPage
            anchors.fill: parent
            visible: root.pageShown("power")
            opacity: root.pageOpacity("power")
            enabled: root.tab === "power"
            s: root.s
            active: root.keyboardActive && root.tab === "power"
            onLeaving: root.leaving()
            onCloseRequested: root.closeRequested()
        }
    }
}
