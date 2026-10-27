pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../strings"

// CPU and memory Readings (data-model "Reading"). Real data comes from /proc/stat and
// /proc/meminfo every 2 s (research R3); the "cpu"/"mem" fixtures are percents.
Singleton {
    id: root

    readonly property bool cpuFixed: Fixtures.has("cpu")
    readonly property bool memFixed: Fixtures.has("mem")

    readonly property var cpu: reading("cpu", Strings.cpu, cpuFixed ? Number(Fixtures.get("cpu")) / 100 : cpuReal)
    readonly property var mem: reading("mem", Strings.mem, memFixed ? Number(Fixtures.get("mem")) / 100 : memReal)

    property real cpuReal: 0
    property real memReal: 0
    property var lastStat: null      // { busy, total } of the previous /proc/stat read

    onCpuFixedChanged: lastStat = null   // the next real read starts a new delta

    function reading(key: string, label: string, value: real): var {
        return {
            key: key,
            label: label,
            value: isFinite(value) ? Math.max(0, Math.min(1, value)) : 0,
            critical: false,
            extra: "none",
            available: true
        };
    }

    // First line of /proc/stat: "cpu user nice system idle iowait irq softirq steal ...".
    function updateCpu(text: string): void {
        const f = (text.split("\n", 1)[0] ?? "").trim().split(/\s+/);
        if (f[0] !== "cpu" || f.length < 5) {
            cpuReal = 0;
            return;
        }
        const n = f.slice(1, 9).map(Number);
        const idle = n[3] + (n[4] || 0);
        const total = n.reduce((a, b) => a + (b || 0), 0);
        const prev = lastStat;
        lastStat = { busy: total - idle, total: total };
        const dt = prev ? total - prev.total : 0;
        cpuReal = dt > 0 ? (lastStat.busy - prev.busy) / dt : 0;
    }

    function updateMem(text: string): void {
        const kb = key => {
            const m = new RegExp(`^${key}:\\s+(\\d+)`, "m").exec(text);
            return m ? Number(m[1]) : NaN;
        };
        const total = kb("MemTotal");
        const avail = kb("MemAvailable");
        memReal = total > 0 ? (total - avail) / total : 0;
    }

    // Runs only while some domain is real: with both fixed, nothing is read.
    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: !(root.cpuFixed && root.memFixed)
        onTriggered: {
            if (!root.cpuFixed)
                stat.reload();
            if (!root.memFixed)
                meminfo.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        printErrors: false
        onLoaded: root.updateCpu(text())
        onLoadFailed: root.cpuReal = 0
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        printErrors: false
        onLoaded: root.updateMem(text())
        onLoadFailed: root.memReal = 0
    }
}
