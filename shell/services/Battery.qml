pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../strings"

// Battery Reading of UPower's display device (research R2), or the "battery" fixture
// (null = no battery, or { percent, charging }). No battery → available false.
Singleton {
    id: root

    readonly property var bat: {
        let value = 0;
        let charging = false;
        let present = false;
        if (Fixtures.has("battery")) {
            const f = Fixtures.get("battery");
            present = f !== null && typeof f === "object";
            value = present ? Number(f.percent) / 100 : 0;
            charging = present && f.charging === true;
        } else {
            const d = upowerInstalled ? UPower.displayDevice : null;
            present = !!d && d.isLaptopBattery && d.isPresent;
            value = present ? d.percentage : 0;
            charging = present && d.state === UPowerDeviceState.Charging;
        }
        value = isFinite(value) ? Math.max(0, Math.min(1, value)) : 0;
        return {
            key: "bat",
            label: Strings.bat,
            value: value,
            critical: present && value < 0.15 && !charging,
            extra: charging ? "charging" : "none",
            available: present
        };
    }

    // Touching UPower without its daemon logs two warnings (quickshell.dbus/service.upower), so
    // it is only used when D-Bus can activate it. Without it there is simply no battery.
    readonly property bool upowerInstalled: upowerService.loaded

    FileView {
        id: upowerService
        path: "/usr/share/dbus-1/system-services/org.freedesktop.UPower.service"
        printErrors: false
    }
}
