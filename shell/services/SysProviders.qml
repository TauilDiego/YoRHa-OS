pragma Singleton

import QtQuick
import Quickshell

// spec 019 (contracts/system-provider.md): "sys.<provider>.<key>" names a row's live source; this
// says which singleton answers each <provider>. A new provider is one more line here.
Singleton {
    function byName(name: string): var {
        switch (name) {
        case "audio":
            return SysAudio;
        case "power":
            return SysPower;
        case "display":
            return SysDisplay;
        case "input":
            return SysInput;
        case "proof":
            return SysProof;
        }
        return null;
    }
}
