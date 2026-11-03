pragma Singleton

import QtQuick
import Quickshell
import "../strings"

// spec 019 (T013): the provider of the catalog of proof (fixtures/settings-proof.json), so the rows'
// mechanics are tested before any real provider exists. Only the "sysProof" fixture feeds it:
// { level: { choice, slider, toggle, info }, list: [{ id, label }], available, reason, failWrites }.
// `available`, `reason`, `failWrites` and the list change with `fixtures load`. A write stays in
// memory, or with failWrites shows for a moment (the optimistic write of the contract) and then goes
// back, with the note. The keys are choice, slider, toggle, info and list (read-only, `opens`).
Singleton {
    id: root

    readonly property var fixture: Fixtures.has("sysProof") ? (Fixtures.get("sysProof") ?? ({})) : ({})
    readonly property var list: Array.isArray(fixture.list) ? fixture.list : []
    property var written: ({})                   // key → what a write left in memory
    property var pending: ({})                   // key → what a failing write shows until it fails
    property string failNote: ""

    function levelsOf(key: string): var {
        return key === "choice" ? list.map(x => String(x.id)) : [];
    }
    function labelsOf(key: string): var {
        return key === "choice" ? list.map(x => String(x.label)) : [];
    }
    function levelOf(key: string): var {
        if (Object.prototype.hasOwnProperty.call(pending, key))
            return pending[key];
        if (Object.prototype.hasOwnProperty.call(written, key))
            return written[key];
        return fixture.level?.[key] ?? null;
    }
    function setLevel(key: string, level: var): void {
        if (key === "info" || key === "list")
            return;
        if (fixture.failWrites === true) {
            pending = Object.assign({}, pending, { [key]: level });
            failSoon.restart();
            return;
        }
        written = Object.assign({}, written, { [key]: level });
        failNote = "";
    }
    function available(key: string): bool {
        return Fixtures.has("sysProof") && fixture.available !== false;
    }
    function reason(key: string): string {
        return available(key) ? "" : String(fixture.reason ?? "");
    }
    function rangeOf(key: string): var {
        return { min: 0, max: 100 };
    }
    function note(key: string): string {
        return failNote;
    }
    function metaOf(key: string): var {
        return key === "info" ? [{ label: "SOURCE", value: "fixture" }] : [];
    }
    function listOf(key: string): var {
        return key === "list" ? list.map(x => String(x.label)) : [];
    }

    Timer {
        id: failSoon
        interval: 100
        onTriggered: {
            root.pending = {};
            root.failNote = Strings.settings.sys.proofWriteFailed;
        }
    }
    Connections {
        target: Fixtures
        function onDataChanged(): void {
            failSoon.stop();
            root.written = {};
            root.pending = {};
            root.failNote = "";
        }
    }
}
