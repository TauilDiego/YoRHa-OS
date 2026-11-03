pragma Singleton

import QtQuick
import Quickshell

// spec 019 (contracts/system-provider.md): the screen rows: the focused monitor's mode, read through Compositor, and the backlight. Etapa 1B fills it in: the keys are
// resolution, refresh, scale, brightness. Until then no catalog row names this provider, so a row is never "unavailable" just
// because the code isn't there yet (FR-004).
Singleton {
    function levelsOf(key: string): var {
        return [];
    }
    function labelsOf(key: string): var {
        return [];
    }
    function levelOf(key: string): var {
        return null;
    }
    function setLevel(key: string, level: var): void {
    }
    function available(key: string): bool {
        return false;
    }
    function reason(key: string): string {
        return "";
    }
    function rangeOf(key: string): var {
        return { min: 0, max: 100 };
    }
}
