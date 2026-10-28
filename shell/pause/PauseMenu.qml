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

    signal closeRequested()

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

    // --- pause dump (contracts/ipc.md) -------------------------------------------------------------
    function dumpState(): var {
        const geo = page?.geometry?.() ?? null;
        return {
            open: keyboardActive,
            monitor: screen?.name ?? "",
            tab: tab,
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
            } else if (root.tab === "apps" && event.text.length > 0 && event.text >= " "
                       && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                appsPage.type(event.text);
                event.accepted = true;
            }
        }

        AppsPage {
            id: appsPage
            anchors.fill: parent
            visible: root.tab === "apps"
            enabled: visible
            s: root.s
            onCloseRequested: root.closeRequested()
        }

        WindowsPage {
            id: windowsPage
            anchors.fill: parent
            visible: root.tab === "windows"
            enabled: visible
            s: root.s
            onCloseRequested: root.closeRequested()
        }

        SettingsPage {
            id: systemPage
            anchors.fill: parent
            visible: root.tab === "system"
            enabled: visible
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
            visible: root.tab === "power"
            enabled: visible
            s: root.s
            active: root.keyboardActive && root.tab === "power"
            onCloseRequested: root.closeRequested()
        }
    }
}
