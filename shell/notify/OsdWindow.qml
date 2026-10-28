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

    property var modelData                       // the ShellScreen
    screen: modelData
    property var osd: null                       // Osd.current, or the last one while fading out
    property bool shown: false
    property real topInset: 0
    readonly property string position: NotifyPrefs.osdPosition
    readonly property real s: Settings.uiScale * Math.min(1, (modelData?.width ?? 1920) / 1920, (modelData?.height ?? 1080) / 1080)
    readonly property real dpr: Tokens.scaleOf(modelData?.name ?? "")
    readonly property var nt: Tokens.notify

    anchors {
        bottom: root.position !== "top"
        top: root.position === "top"
    }
    readonly property real bottomGap: Tokens.px(nt.osdBottom, s)
    readonly property real topGap: topInset > 0 ? Math.round(topInset + Tokens.px(nt.osdTop, s)) : Settings.barHeight + Tokens.px(nt.osdTop, s)
    // qmllint disable missing-property
    margins {                                    // an opaque value type to qmllint (Quickshell 0.3.2)
        bottom: root.bottomGap
        top: root.topGap
    }
    // qmllint enable missing-property
    implicitWidth: view.implicitWidth + Tokens.px(nt.shadow, s)
    implicitHeight: view.implicitHeight + Tokens.px(nt.shadow, s)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rien-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    mask: Region {}

    readonly property var ostr: Strings.notify
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
                return root.osd?.muted ? root.ostr.micOff : root.ostr.micOn;
            return k === "brightness" ? root.ostr.brightness : root.ostr.volume;
        }
        valueText: root.osd?.kind === "volume" && root.osd?.muted ? root.ostr.mute
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
        const sw = modelData?.width ?? 0, sh = modelData?.height ?? 0;
        const x = Math.round((sw - implicitWidth) / 2);
        const y = position === "top" ? Math.round(topGap) : Math.round(sh - bottomGap - implicitHeight);
        return { x: x, y: y, w: w, h: h };
    }
}
