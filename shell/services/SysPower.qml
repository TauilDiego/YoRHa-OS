pragma Singleton

import QtQuick
import Quickshell
import "../strings"

// spec 019 (contracts/system-provider.md, FR-019, R8): the Battery row says what Battery.qml reads
// ("64%", "87% · charging"), or dims with why it can't. It only reads: nothing here touches the
// system, and nothing is saved. The fixture's "battery" domain comes through Battery.qml.
Singleton {
    function levelsOf(key: string): var {
        return [];
    }
    function labelsOf(key: string): var {
        return [];
    }
    function levelOf(key: string): var {
        const bat = Battery.bat;
        if (key !== "battery" || !bat.available)
            return "";
        const percent = `${Math.round(bat.value * 100)}%`;
        return bat.extra === "charging" ? `${percent} · ${Strings.settings.sys.charging}` : percent;
    }
    function setLevel(key: string, level: var): void {
    }
    function available(key: string): bool {
        return key === "battery" && Battery.bat.available;
    }
    function reason(key: string): string {
        if (available(key))
            return "";
        // Under the fixture, the machine "has" UPower: `null` there means no battery.
        return Fixtures.has("battery") || Battery.upowerInstalled ? Strings.settings.sys.noBattery : Strings.settings.sys.noUpower;
    }
    function rangeOf(key: string): var {
        return { min: 0, max: 100 };
    }
}
