pragma ComponentBehavior: Bound

import QtQuick
import "../ds"
import "../services"

// Shows one wallpaper and changes it with a transition (spec 004, research R2, R4, R5).
// Two slots hold wallpapers: the one on screen and the one coming in. While a change runs, both
// become live textures (ShaderEffectSource) that one ShaderEffect (shaders/transition.frag) mixes;
// when it ends, the old slot is emptied and the effect goes away (nothing costs while idle).
// A change in the middle of another starts from what is on screen (FR-017): the running one is
// paused and grabbed once, and the new change goes from that still frame.
// `instant` (fixtures, reduced motion) swaps without a transition. Without the compiled shader
// (.qsb) every transition is a plain crossfade, with one warning.
Item {
    id: root

    property string current: ""                  // the id to show
    property real s: 1
    property real phase: 0
    property real dpr: 1                         // the monitor's real scale
    property string kind: "camouflage"
    property int cell: 24
    property int trail: 2600
    property int glitch: 2
    property bool instant: false
    property var paperFilterOff: []

    // Read by `wallpaper dump`.
    readonly property bool running: anim.running || freezing || waiting
    property real elapsed: 0
    property real seed: 1
    property point origin: Qt.point(0.5, 0.5)
    property string runKind: kind                // fixed when a change starts

    readonly property size physical: Qt.size(Math.round(width * dpr), Math.round(height * dpr))
    readonly property real progress: {
        const p = Math.min(1, elapsed / Tokens.wallpaper.duration);
        return p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;   // ease in-out
    }
    readonly property int duration: runKind === "camouflage"
        ? Tokens.wallpaper.reveal + trail + Tokens.wallpaper.settle
        : Tokens.wallpaper.duration
    readonly property bool shaderOk: effect.status !== ShaderEffect.Error

    // --- the two slots ---------------------------------------------------------------------------
    property string aId: ""
    property string bId: ""
    property bool shownIsA: true                 // idle: the slot on screen
    property bool toIsA: true                    // during a change: the slot coming in
    property bool waiting: false                 // the incoming slot is loading
    property bool fromFrozen: false              // the change starts from a grabbed frame
    property bool freezing: false
    readonly property Item toSlot: toIsA ? slotA : slotB

    WallpaperView {
        id: slotA
        anchors.fill: parent
        z: root.shownIsA ? 1 : 0
        visible: root.aId !== ""
        wallpaper: WallpaperCatalog.byId(root.aId)
        s: root.s
        phase: root.phase
        screenSize: root.physical
        paperFilter: !root.paperFilterOff.includes(wallpaper?.path ?? "")
        onReadyChanged: root.tryBegin()
    }
    WallpaperView {
        id: slotB
        anchors.fill: parent
        z: root.shownIsA ? 0 : 1
        visible: root.bId !== ""
        wallpaper: WallpaperCatalog.byId(root.bId)
        s: root.s
        phase: root.phase
        screenSize: root.physical
        paperFilter: !root.paperFilterOff.includes(wallpaper?.path ?? "")
        onReadyChanged: root.tryBegin()
    }

    // A still frame of an interrupted change, on top while the next one gets ready.
    Image {
        id: frozen
        anchors.fill: parent
        z: 2
        visible: root.fromFrozen
        cache: false
    }

    // --- the effect ------------------------------------------------------------------------------
    readonly property bool animating: anim.running          // true while paused for a grab, too
    readonly property Item fromItem: fromFrozen ? frozen : (toIsA ? slotB : slotA)

    ShaderEffectSource {
        id: fromTexture
        sourceItem: root.animating && root.shaderOk ? root.fromItem : null
        hideSource: true
        live: true
        textureSize: root.physical
    }
    ShaderEffectSource {
        id: toTexture
        sourceItem: root.animating && root.shaderOk ? root.toSlot : null
        hideSource: true
        live: true
        textureSize: root.physical
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent
        z: 3
        visible: root.animating && root.shaderOk
        fragmentShader: Qt.resolvedUrl("../shaders/transition.frag.qsb")

        property variant source: fromTexture
        property variant target: toTexture
        readonly property real mode: ["camouflage", "wipe", "tiles", "crossfade"].indexOf(root.runKind)
        readonly property real elapsed: root.elapsed
        readonly property real progress: root.progress
        readonly property real revealMs: Tokens.wallpaper.reveal
        readonly property real leadMs: Tokens.wallpaper.lead
        readonly property real trailMs: root.trail
        readonly property real cell: root.cell * root.s
        readonly property real glitch: [0, 0.0008, 0.006][root.glitch] ?? 0
        readonly property real seed: root.seed
        readonly property real frame: Math.floor(root.elapsed / 33.3)
        readonly property real unit: root.s
        readonly property real line: Tokens.hair(2 * root.s, root.dpr)
        readonly property real inkSquare: Tokens.wallpaper.inkSquare
        readonly property point origin: root.origin
        readonly property size itemSize: Qt.size(root.width, root.height)
        readonly property color ink: Tokens.color.darkGray
        readonly property color light: Tokens.wallpaper.glint
    }

    // Without the shader: the incoming slot fades in over the old one.
    Binding {
        target: root.toSlot
        property: "opacity"
        value: root.progress
        when: root.animating && !root.shaderOk
    }
    Binding {
        target: root.toSlot
        property: "z"
        value: 1.5
        when: root.animating && !root.shaderOk
    }

    WipeEdge {
        z: 4
        visible: root.animating && root.shaderOk && root.runKind === "wipe"
        x: root.progress * (root.width + 40 * root.s)
        length: root.height
        s: root.s
    }

    NumberAnimation {
        id: anim
        target: root
        property: "elapsed"
        from: 0
        to: root.duration
        duration: root.duration
        onFinished: root.finish()
    }

    // --- changes ---------------------------------------------------------------------------------
    onCurrentChanged: Qt.callLater(change)
    Component.onCompleted: change()

    function shownId(): string {
        return shownIsA ? aId : bId;
    }

    function setSlot(isA: bool, id: string): void {
        if (isA)
            aId = id;
        else
            bId = id;
    }

    // --- spec 004 T041: a still frame for the gallery ----------------------------------------------
    // Holds the running change at `ms`, with seed 1 and the origin in the middle, so the frame is
    // the same every time.
    function hold(ms: real): void {
        anim.pause();
        seed = 1;
        origin = Qt.point(0.5, 0.5);
        elapsed = ms;
    }
    // --- end spec 004 T041

    function change(): void {
        const id = current;
        if (id === "" || freezing)
            return;
        if (shownId() === "" && !anim.running && !waiting) {        // the first one: just show it
            setSlot(shownIsA, id);
            return;
        }
        if (anim.running) {
            interrupt();
            return;
        }
        if (waiting) {                                              // still loading: retarget
            if (id === shownId() && !fromFrozen) {
                waiting = false;
                setSlot(toIsA, "");
            } else {
                setSlot(toIsA, id);
                tryBegin();
            }
            return;
        }
        if (id === shownId())
            return;
        toIsA = !shownIsA;
        setSlot(toIsA, id);
        waiting = true;
        tryBegin();
    }

    // The incoming slot is ready: run the transition (or swap at once).
    function tryBegin(): void {
        if (!waiting || !toSlot.ready || (toIsA ? aId : bId) === "")
            return;
        waiting = false;
        if (instant) {
            finish();
            return;
        }
        if (!shaderOk && !warnedShader) {
            warnedShader = true;
            console.warn("wallpaper: shaders/transition.frag.qsb is missing (run shaders/build.sh); using a crossfade");
        }
        runKind = shaderOk ? kind : "crossfade";
        seed = Math.floor(Math.random() * 1000) + 1;
        origin = Qt.point(0.5 + (Math.random() - 0.5) * 0.3, 0.5 + (Math.random() - 0.5) * 0.3);
        elapsed = 0;
        anim.restart();
    }
    property bool warnedShader: false

    // The incoming slot is now the one on screen.
    function finish(): void {
        anim.stop();
        shownIsA = toIsA;
        setSlot(!toIsA, "");
        fromFrozen = false;
        frozen.source = "";
        elapsed = 0;
        if (current !== shownId())                                  // asked for meanwhile
            Qt.callLater(change);
    }

    // A change in the middle of another: hold the frame, grab it, go on from it.
    function interrupt(): void {
        if (current === (toIsA ? aId : bId))
            return;                                                 // already heading there
        anim.pause();
        freezing = true;
        const ok = root.grabToImage(result => {
            frozen.source = result.url;
            freezing = false;
            fromFrozen = true;
            anim.stop();
            elapsed = 0;
            // Keep a slot that already holds the new id; empty the rest.
            const id = current;
            toIsA = bId === id ? false : true;
            setSlot(!toIsA, "");
            setSlot(toIsA, id);
            waiting = true;
            tryBegin();
        }, physical);
        if (!ok) {                                                  // no grab: jump to the end
            freezing = false;
            finish();
        }
    }
}
