pragma Singleton

import QtQuick
import Quickshell

// Wall clock (data-model "Clock"): SystemClock at second precision, or the fixed local time of
// the "clock" fixture ("2026-10-26T13:37:00").
Singleton {
    id: root

    readonly property var fixedDate: Fixtures.has("clock") ? parseLocal(Fixtures.get("clock")) : null
    // `clock.date` can still be undefined for a moment during a hot reload (seen since spec 008):
    // the current time then, instead of a QML warning.
    readonly property date date: fixedDate ?? clock.date ?? new Date()
    readonly property string dateText: Qt.formatDateTime(date, "yyyy.MM.dd")
    readonly property string timeText: Qt.formatDateTime(date, "HH:mm:ss")

    // "YYYY-MM-DDTHH:mm[:ss]" read as local time; anything else → null (real clock).
    function parseLocal(text: var): var {
        const m = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?$/.exec(String(text ?? ""));
        if (!m)
            return null;
        const d = new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +(m[6] ?? 0));
        return isNaN(d.getTime()) ? null : d;
    }

    SystemClock {
        id: clock
        enabled: root.fixedDate === null
        precision: SystemClock.Seconds
    }
}
