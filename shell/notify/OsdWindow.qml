import QtQuick
import Quickshell
import Quickshell.Wayland
import "../ds"
import "../ds/composites"
import "../services"
import "../strings"

// The OSD's window (spec 008, R9, FR-028–FR-030): only as big as the OSD, centered on the monitor of
// the change, at the bottom (Tokens.notify.osdBottom above the edge) or at the top (under the bar, or
// under the critical band when there is one: `topInset`). No input at all (an empty mask, no
// keyboard). It fades in and out (Tokens.notify.fade; instantly when frozen or with reduced motion);
// shell.qml creates it while there is an OSD and unloads it after the fade.
PanelWindow {
    id: root

    property var osd: null                       // Osd.current, or the last one while fading out
    property bool shown: false
    property real topInset: 0
    readonly property string position: NotifyPrefs.osdPosition
    readonly property real s: Settings.uiScale * Math.min(1, (screen?.width ?? 1920) / 1920, (screen?.height ?? 1080) / 1080)
    readonly property real dpr: Tokens.scaleOf(screen?.name ?? "")
    readonly property var N: Tokens.notify

    anchors {
        bottom: root.position !== "top"
        top: root.position === "top"
    }
    margins {
        bottom: Tokens.px(N.osdBottom, s)
        top: topInset > 0 ? Math.round(topInset + Tokens.px(N.osdTop, s)) : Settings.barHeight + Tokens.px(N.osdTop, s)
    }
    implicitWidth: view.implicitWidth + Tokens.px(N.shadow, s)
    implicitHeight: view.implicitHeight + Tokens.px(N.shadow, s)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rien-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    mask: Region {}

    readonly property var O: Strings.notify
    OsdView {
        id: view
        s: root.s
        dpr: root.dpr
        opacity: 0
        meter: root.osd?.meter ?? true
        muted: root.osd?.muted === true
        value: root.osd?.value ?? 0
        label: {
            const k = root.osd?.kind ?? "volume";
            if (k === "mic")
                return root.osd?.muted ? root.O.micOff : root.O.micOn;
            return k === "brightness" ? root.O.brightness : root.O.volume;
        }
        valueText: root.osd?.kind === "volume" && root.osd?.muted ? root.O.mute
                 : root.osd?.kind === "mic" ? "" : String(root.osd?.value ?? 0)
    }
    NumberAnimation {
        id: fade
        target: view
        property: "opacity"
        duration: Tokens.notify.fade
    }
    function apply(): void {
        fade.stop();
        const want = shown ? 1 : 0;
        if (Tokens.instant) {
            view.opacity = want;
            return;
        }
        fade.from = view.opacity;
        fade.to = want;
        fade.start();
    }
    onShownChanged: apply()
    Component.onCompleted: apply()

    function box(): var {
        const w = Math.round(view.width), h = Math.round(view.height);
        const sw = screen?.width ?? 0, sh = screen?.height ?? 0;
        const x = Math.round((sw - implicitWidth) / 2);
        const y = position === "top" ? Math.round(margins.top) : Math.round(sh - margins.bottom - implicitHeight);
        return { x: x, y: y, w: w, h: h };
    }
}
