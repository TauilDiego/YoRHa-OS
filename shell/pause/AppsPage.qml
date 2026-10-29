pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../ds/base"
import "../ds/composites"
import "../ds/primitives"
import "../services"
import "../strings"

// The pause menu's APPS, the launcher (spec 007 US2, FR-009–FR-014): the PickerLayout of spec 004
//   list     PINNED, then ALL APPS (A–Z, or most used first: `order`), each app with its open
//            windows on the right; while the user types, only the results (best first) under the
//            search header, or "No apps match.";
//   preview  a Card with the app's name, its icon (AppIcon, `iconStyle`) in a light-gray box, its
//            description and how often it was opened;
//   options  Open, the app's own actions, Workspace ◂ Current ▸ (where it opens) and Pinned
//            ◂ ON ▸; then CATEGORY, COMMAND and WINDOWS.
// The menu sends every printable key here (type); Backspace takes one character off; Escape on
// the list clears the search, or closes. Enter (or Open) launches the app and closes the menu;
// with `runningApp` "focus", Enter on an app that has a window goes to its latest one instead.
// The cursor follows the app (not the row), so pinning moves it along with the app (FR-013).
FocusScope {
    id: root

    property real s: 1
    property real startY: Tokens.space.pauseBodyY
    // The SYSTEM › Pause menu options, live (FR-034).
    property string iconStyle: SettingsModel.choiceId("menu", "icons") || "ink"
    property string order: SettingsModel.choiceId("menu", "app-order") || "az"
    property string runningApp: SettingsModel.choiceId("menu", "running-app") || "new"

    signal closeRequested()

    readonly property var ps: Strings.pause

    // --- the list ------------------------------------------------------------------------------------
    property string query: ""
    readonly property bool searching: query !== ""
    readonly property var resultIds: searching ? Apps.search(query) : []
    readonly property var entries: {
        if (!searching)
            return Apps.listed(order);
        return resultIds.map(id => {
            const n = Apps.windowsOf(id).length;
            return { label: Apps.byId(id)?.name ?? id, trailing: n > 0 ? String(n) : "", id: id };
        });
    }
    readonly property var itemIds: entries.filter(e => e.group === undefined).map(e => e.id)

    property string currentId: ""
    readonly property int index: Math.max(0, itemIds.indexOf(currentId))
    readonly property var app: itemIds.length > 0 ? Apps.byId(itemIds[index]) : null
    property int workspace: 0                    // 0 = Current, else 1–10

    onIndexChanged: layout.index = index
    onItemIdsChanged: {
        if (!itemIds.includes(currentId))
            currentId = itemIds[0] ?? "";
        layout.index = index;
        refollow.restart();
    }
    // The list scrolls to its cursor when the cursor moves; when only the rows move (an app
    // pinned or unpinned), it scrolls once they are laid out again.
    Timer {
        id: refollow
        interval: 20
        onTriggered: layout.groupedList.follow()
    }
    // A new search puts the cursor on its first result.
    onQueryChanged: {
        if (searching) {
            currentId = itemIds[0] ?? "";
            layout.index = index;
        }
    }

    // Only printable text: no C0 controls, no DEL, no C1 controls.
    function printable(text: string): string {
        return String(text ?? "").replace(/[\u0000-\u001f\u007f-\u009f]/g, "");
    }

    function type(text: string): void {
        const t = printable(text);
        if (t === "")
            return;
        layout.column = "list";
        query += t;
    }
    function backspace(): void {
        if (!searching)
            return;
        layout.column = "list";
        query = Array.from(query).slice(0, -1).join("");
    }
    function clear(): void {
        layout.column = "list";
        query = "";
    }
    // Tests only (`pause search`): the whole search at once.
    function setQuery(text: string): void {
        layout.column = "list";
        query = printable(text);
    }

    // --- options and info -----------------------------------------------------------------------------
    readonly property var workspaceValues: [ps.current].concat([1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(n => String(n).padStart(2, "0")))
    readonly property var options: {
        const a = app;
        if (!a)
            return [];
        const out = [{ id: "open", label: ps.open, type: "action", text: ps.open }];
        a.actions.forEach((x, i) => out.push({ id: `action-${i}`, label: x.name, type: "action", text: ps.open }));
        out.push({ id: "workspace", label: ps.workspace, type: "choice", values: workspaceValues });
        out.push({ id: "pinned", label: ps.pinnedOption, type: "toggle" });
        return out;
    }
    readonly property var values: ({ workspace: workspace, pinned: app?.pinned ? 1 : 0 })
    readonly property int appWindows: app ? Apps.windowsOf(app.id).length : 0
    readonly property string commandText: {
        if (!app)
            return "";
        const c = Apps.cleanArgv(app.command).join(" ");
        return app.terminal ? ps.inTerminal.arg(c) : c;
    }
    readonly property var info: app ? [
        { label: ps.category, value: ps.categories[app.category] ?? app.category },
        { label: ps.command, value: commandText },
        { label: ps.windows, value: appWindows > 0 ? String(appWindows) : ps.none }
    ] : []

    // --- acting ---------------------------------------------------------------------------------------
    // Open the app (action -1) or one of its actions, then close the menu at once. With "Go to
    // window", Enter on an app with windows focuses its latest one instead.
    function launch(action: int): void {
        const a = app;
        if (!a)
            return;
        if (action < 0 && runningApp === "focus") {
            const w = Apps.windowsOf(a.id);
            if (w.length > 0) {
                const r = Compositor.focusWindow(w[0].id);
                if (r !== "ok")
                    console.info(`apps: ${r}`);
                closeRequested();
                return;
            }
        }
        const r = Apps.launch(a.id, action, workspace);
        if (r !== "ok")
            console.info(`apps: ${r}`);
        closeRequested();
    }

    function trigger(o: int): void {
        const id = String(options[o]?.id ?? "");
        if (id === "open")
            launch(-1);
        else if (id.startsWith("action-"))
            launch(Number(id.slice(7)));
    }

    function pick(o: int, v: int): void {
        switch (options[o]?.id) {
        case "workspace":
            workspace = Math.max(0, Math.min(10, v));
            break;
        case "pinned":
            Apps.setPinned(app.id, v === 1);
            break;
        }
    }

    // --- what the menu reads --------------------------------------------------------------------------
    readonly property var keys: {
        const k = layout.keys.slice();
        if (layout.column === "list" && searching && k.length > 0)
            k[k.length - 1] = { key: Strings.settings.keyEsc, label: ps.clear };
        return k;
    }
    readonly property string footerLeft: ps.appsFooter.arg(Apps.count)

    // A fresh menu: no search, the cursor on the first app, the list focused, Current workspace.
    function restart(): void {
        query = "";
        workspace = 0;
        currentId = itemIds[0] ?? "";
        layout.restart(index);
    }
    function enter(): void {
    }
    function leave(): void {
    }
    function geometry(): var {
        return layout.geometry();
    }

    function entryText(e: var): string {
        if (e.group !== undefined)
            return String(e.group);
        return String(e.label) + (e.trailing ? " " + e.trailing : "");
    }

    function dumpState(): var {
        const o = layout.column === "options" ? (options[layout.option]?.id ?? null) : null;
        const shown = entries.map(e => entryText(e));
        if (searching && itemIds.length === 0)
            shown.push(ps.noMatch);
        return {
            column: layout.column,
            query: query,
            item: app?.id ?? "",
            entries: shown,
            results: resultIds,
            option: o,
            workspace: workspace === 0 ? ps.current : workspaceValues[workspace],
            preview: {
                title: preview.title,
                text: preview.text,
                footer: preview.footer,
                iconStyle: iconStyle,
                icon: icon.shown,
                drawn: app ? icon.drawn : "none"
            },
            info: info.map(r => `${r.label}: ${r.value}`),
            order: order,
            runningApp: runningApp,
            error: Apps.error
        };
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Backspace && searching) {
            backspace();
            event.accepted = true;
        }
    }

    PickerLayout {
        id: layout
        anchors.fill: parent
        focus: true
        s: root.s
        startY: root.startY
        entries: root.entries
        options: root.options
        values: root.values
        info: root.info
        optionsTitle: root.ps.appOptions
        applyLabel: root.ps.open
        searchHeader: root.searching ? { query: root.query, count: root.itemIds.length } : null
        emptyText: root.searching ? root.ps.noMatch : ""
        onIndexChanged: {
            const id = root.itemIds[index];
            if (id !== undefined)
                root.currentId = id;
        }
        onApplied: root.launch(-1)
        onTriggered: o => root.trigger(o)
        onPicked: (o, v) => root.pick(o, v)
        onCloseRequested: {
            if (root.searching)
                root.clear();
            else
                root.closeRequested();
        }

        // The preview: the app's name, its icon in a light-gray box, its description and how often
        // it was opened (the mockup's APPS card).
        Item {
            id: preview
            width: layout.previewWidth
            implicitHeight: textBlock.y + textBlock.height + pad
            height: implicitHeight

            readonly property int pad: Tokens.px(24, root.s)
            readonly property var app: root.app
            readonly property string title: Apps.error !== "" ? Strings.pause.tabs.apps.title
                : app ? app.name : root.ps.noMatchTitle
            readonly property string text: Apps.error !== "" ? Apps.error
                : app ? app.description : root.ps.noMatchText
            readonly property string footer: !app ? ""
                : app.uses === 0 ? root.ps.neverOpened
                : app.uses === 1 ? root.ps.openedOnce : root.ps.opened.arg(app.uses)

            Card {
                anchors.fill: parent
                s: root.s
                mark: true
                title: preview.title
            }

            Rectangle {
                id: box
                x: Math.round((preview.width - width) / 2)
                y: Tokens.px(49, root.s) + preview.pad
                width: Tokens.px(Tokens.space.mapW, root.s)
                height: Tokens.px(Tokens.space.mapH, root.s)
                color: Tokens.color.lightGray

                AppIcon {
                    id: icon
                    anchors.centerIn: parent
                    visible: preview.app !== null
                    s: root.s
                    size: Tokens.space.appIconSize
                    style: root.iconStyle
                    source: preview.app?.icon ?? ""
                    fallback: preview.app?.categoryIcon ?? ""
                }

                // No result: a magnifier in ink (the mockup's search glyph).
                Item {
                    anchors.centerIn: parent
                    width: Tokens.px(120, root.s)
                    height: width
                    visible: preview.app === null && Apps.error === ""

                    Rectangle {
                        x: 0
                        y: 0
                        width: Tokens.px(76, root.s)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: Tokens.line(7, root.s)
                        border.color: Tokens.color.darkGray
                    }
                    Rectangle {
                        x: Tokens.px(64, root.s)
                        y: Tokens.px(78, root.s)
                        width: Tokens.px(52, root.s)
                        height: Tokens.line(9, root.s)
                        rotation: 45
                        transformOrigin: Item.Left
                        color: Tokens.color.darkGray
                    }
                }
            }

            Item {
                id: textBlock
                x: preview.pad
                y: box.y + box.height + Tokens.px(18, root.s)
                width: preview.width - 2 * preview.pad
                height: Math.max(Tokens.px(66, root.s), Math.ceil(description.implicitHeight))
                        + (footerLabel.text !== "" ? Tokens.px(18, root.s) + footerLabel.implicitHeight : 0)

                // As the mockup's preview text: 23 px, weight 500, lines 1.45 × the size apart.
                Label {
                    id: description
                    width: parent.width
                    s: root.s
                    role: "standard"
                    font.weight: Font.Medium
                    font.variableAxes: ({ "wght": Font.Medium })
                    lineHeightMode: Text.FixedHeight
                    lineHeight: Math.round(size * 1.45)
                    wrapMode: Text.Wrap
                    text: preview.text
                }

                Label {
                    id: footerLabel
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    s: root.s
                    role: "small"
                    font.pixelSize: Tokens.px(20, root.s)
                    text: preview.footer
                }
            }
        }
    }
}
