pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import "ds"
import "components"

// The YoRHa-OS login (spec 011, US1 and US3): the approved mockup ("YoRHa-OS Login: proposta", v3.2,
// lab/mockups/login) as an SDDM theme. The SDDM loads this file once per screen; the panels go on the
// primary one and the others show only the paper and the rules (FR-036). Everything is laid out in
// the game's 1920×1080 px and scaled by the screen's height (`s`, FR-037).
// One state machine (components/GreeterState) owns every animation: entering a state stops the
// previous state's ones, and a key, Enter or a click during the entry cut it short, keeping what was
// typed (owner, 29.10; FR-018, FR-020).
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#000000"

    readonly property bool primary: typeof primaryScreen === "undefined" || primaryScreen === true
    readonly property real s: height > 0 ? height / 1080 : 1
    function u(v: real): int {
        return Tokens.px(v, root.s);
    }

    // --- options (theme.conf, with theme.conf.user = /etc/yorha-os/login.conf over it; FR-031) -------
    function option(key: string, allowed: var): string {
        let v = "";
        if (typeof config !== "undefined" && config !== null)
            v = typeof config.stringValue === "function" ? config.stringValue(key) : String(config[key] ?? "");
        v = String(v ?? "").trim();
        if (v === "")
            return allowed[0];
        if (allowed.indexOf(v) >= 0)
            return v;
        if (primary)
            console.log("yorha-login: option " + key + "=" + v + " invalid, using " + allowed[0]);
        return allowed[0];
    }
    readonly property string introOption: option("intro", ["full", "fade", "none"])
    readonly property string clockOption: option("clock", ["big", "small", "none"])
    readonly property string userListOption: option("userList", ["always", "auto"])
    readonly property bool reduceMotion: ["true", "on"].indexOf(option("reduceMotion", ["false", "true", "off", "on"])) >= 0

    // --- the SDDM ----------------------------------------------------------------------------------
    SddmLink {
        id: link
        onFailed: root.failed()
        onSucceeded: root.succeeded()
    }

    // --- selection ----------------------------------------------------------------------------------
    property int sel: 0                          // users.length = "Other user…"
    property int sessionIndex: 0
    property bool picked: false                  // the user moved the selection: a late model reload keeps it
    readonly property bool otherUser: sel >= link.users.length
    // The users load after the screen: until then the selection sits on "Other user…" and the name
    // field has the focus; once it moves, the keys must go to the field that is shown.
    onOtherUserChanged: focusField()
    readonly property bool showUsers: userListOption === "always" || link.users.length !== 1
    readonly property string sessionName: link.sessions.length > 0 ? link.sessions[sessionIndex] ?? "" : ""
    readonly property string selectedLabel: otherUser ? auth.userName.trim() : (link.users[sel]?.label ?? "")

    Connections {
        target: link
        function onUsersChanged(): void {
            if (!root.picked)
                root.sel = link.lastUser;
            root.sel = Math.min(root.sel, link.users.length);
        }
        function onSessionsChanged(): void {
            root.sessionIndex = Math.min(link.lastSession, Math.max(0, link.sessions.length - 1));
        }
    }

    function select(i: int): void {
        const n = link.users.length + 1;
        i = ((i % n) + n) % n;
        picked = true;
        if (i === sel)
            return;
        sel = i;
        auth.clearPassword(true);
        setMessage("", false);
        focusField();
    }
    function stepSession(d: int): void {
        const n = link.sessions.length;
        if (n > 0)
            sessionIndex = ((sessionIndex + d) % n + n) % n;
    }
    // The field the user would type into now: the name first, while "Other user…" has none.
    function focusField(): void {
        if (dialog.visible)
            return;
        if (otherUser && auth.userName.trim() === "")
            auth.focusName();
        else
            auth.focusPassword();
    }

    // --- the message line -----------------------------------------------------------------------------
    property string message: ""
    property bool messageError: false
    readonly property string capsText: "Caps Lock is on."
    function setMessage(text: string, error: bool): void {
        message = text;
        messageError = error;
    }
    function capsCheck(): void {
        if (typeof keyboard !== "undefined" && keyboard.capsLock)
            setMessage(capsText, false);
    }
    Connections {
        target: typeof keyboard !== "undefined" ? keyboard : null
        function onCapsLockChanged(): void {
            if (keyboard.capsLock && !root.messageError)
                root.setMessage(root.capsText, false);
            else if (!keyboard.capsLock && root.message === root.capsText)
                root.setMessage("", false);
        }
    }

    // --- the state machine ----------------------------------------------------------------------------
    GreeterState {
        id: greeter
        logging: root.primary
        owned: ({
            intro: [introFull, introFade, title, startGate],
            ready: [tear],
            welcome: [welcomeSeq],
            leaving: [leaveSeq, leaveSafety]
        })
        onEntered: (state, previous) => root.entered(state, previous)
    }

    // What the screen shows; the timelines animate these.
    property real paperShown: 0
    property real uiShown: 0
    property real usersIn: 0
    property real centerIn: 0
    property real authIn: 0
    property real welcomeShown: 0
    property bool titleShown: false
    property real titleOpacity: 1
    property string bridgeMode: "off"
    property string bridgeText: "Loading user data…"
    property real authShift: 0                   // the tear, game px
    property string introMode: "fade"

    readonly property var ease: [0.25, 0.1, 0.25, 1, 1, 1]      // CSS "ease"

    function rest(): void {
        paperShown = 1;
        uiShown = 1;
        usersIn = 1;
        centerIn = 1;
        authIn = 1;
        welcomeShown = 0;
        titleShown = false;
        bridgeMode = "off";
        authShift = 0;
    }
    function dark(): void {
        paperShown = 0;
        uiShown = 0;
        usersIn = 0;
        centerIn = 0;
        authIn = 0;
        welcomeShown = 0;
        titleShown = false;
        titleOpacity = 1;
        title.dark = false;
        bridgeMode = "off";
        bridgeText = "Loading user data…";
        authShift = 0;
    }

    function entered(state: string, previous: string): void {
        if (state === "intro") {
            dialog.close();
            setMessage("", false);
            auth.clearPassword(false);
            dark();
            introMode = decideIntro(previous);
            if (primary)
                console.log("yorha-login: intro=" + introMode);
            focusField();
            startGate.arm();
        } else if (state === "ready") {
            rest();
            auth.locked = false;
            auth.busy = false;
            focusField();
        } else if (state === "checking") {
            setMessage("", false);
            auth.locked = true;
            auth.busy = true;
        } else if (state === "welcome") {
            auth.busy = false;
            welcome.user = selectedLabel;
            welcome.session = sessionName;
            welcomeSeq.start();
        } else if (state === "leaving") {
            leaveSeq.start();
            leaveSafety.start();
        }
    }

    // The intro waits for the screen's first frame, so its start is never lost behind the window
    // coming up; a key or a click before that cuts it all the same.
    QtObject {
        id: startGate
        property bool armed: false
        function arm(): void {
            armed = true;
            if (root.Window.window && root.Window.window.visible && seen)
                fire();
        }
        property bool seen: false
        function fire(): void {
            if (!armed)
                return;
            armed = false;
            (root.introMode === "full" ? introFull : introFade).start();
        }
        function stop(): void {
            armed = false;
        }
    }
    Connections {
        target: root.Window.window
        enabled: !startGate.seen
        function onFrameSwapped(): void {
            startGate.seen = true;
            Qt.callLater(startGate.fire);
        }
    }
    Timer {
        interval: 1500
        running: startGate.armed
        onTriggered: { startGate.seen = true; startGate.fire(); }
    }

    // full only on the first greeter after the boot: the boot's handoff mark (written by the
    // sddm.service drop-in) is younger than 30 s and no greeter used it yet; a logout or a user
    // switch gets the fade (FR-019). The used mark is kept in the sddm user's cache.
    Settings {
        id: memory
        location: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation) + "/yorha-os/greeter.conf"
        property string handoffUsed: ""
    }
    function readFile(path: string): string {
        try {
            const x = new XMLHttpRequest();
            x.open("GET", "file://" + path, false);
            x.send(null);
            return x.responseText ?? "";
        } catch (e) {
            return "";
        }
    }
    function decideIntro(previous: string): string {
        if (!primary)
            return "fade";
        if (introOption === "fade" || reduceMotion || previous === "leaving")
            return "fade";
        const mark = readFile("/run/yorha-os/handoff").trim();
        const handoff = parseFloat(mark);
        const uptime = parseFloat(readFile("/proc/uptime"));
        if (!isFinite(handoff) || !isFinite(uptime) || uptime < handoff || uptime - handoff >= 30 || mark === memory.handoffUsed)
            return "fade";
        memory.handoffUsed = mark;
        memory.sync();
        return "full";
    }

    function cut(): void {
        if (greeter.current === "intro")
            greeter.enter("ready");
    }

    Component.onCompleted: {
        Tokens.reduced = reduceMotion;
        sel = link.users.length > 0 ? link.lastUser : 0;
        sessionIndex = link.lastSession;
        if (introOption === "none")
            greeter.enter("ready");
        else
            greeter.enter("intro");
    }

    // --- logging in ------------------------------------------------------------------------------------
    function submit(): void {
        if (greeter.current !== "ready")
            return;
        const name = otherUser ? auth.userName.trim() : (link.users[sel]?.name ?? "");
        if (name === "") {
            setMessage("Enter a user name.", true);
            auth.focusName();
            return;
        }
        greeter.enter("checking");
        link.login(name, auth.password, sessionIndex);
    }
    function failed(): void {
        if (greeter.current !== "checking")
            return;
        greeter.enter("ready");
        setMessage("Authentication failed.", true);
        auth.clearPassword(true);
        tear.start();
        auth.focusPassword();
    }
    function succeeded(): void {
        if (greeter.current === "checking")
            greeter.enter("welcome");
    }

    // --- keys (FR-007, FR-018): the fields send every key here first ----------------------------------
    function handleKey(event: var, field: string): void {
        const k = event.key;
        const enter = k === Qt.Key_Return || k === Qt.Key_Enter;
        // During the entry any key but a lone modifier cuts it, and then counts as usual: a letter goes
        // into the field, an arrow moves the selection. An Enter with nothing typed only cuts it.
        const modifier = k === Qt.Key_Shift || k === Qt.Key_Control || k === Qt.Key_Alt || k === Qt.Key_Meta
            || k === Qt.Key_AltGr || k === Qt.Key_CapsLock || k === Qt.Key_Super_L || k === Qt.Key_Super_R;
        if (greeter.current === "intro" && !modifier) {
            cut();
            if (enter && auth.password === "" && auth.userName.trim() === "") {
                event.accepted = true;
                return;
            }
        }
        if (greeter.current !== "ready") {
            event.accepted = true;                // checking, welcome, leaving: the field and Enter wait
            return;
        }
        if (k === Qt.Key_Up || k === Qt.Key_Down) {
            if (showUsers)
                select(sel + (k === Qt.Key_Up ? -1 : 1));
            event.accepted = true;
        } else if (k === Qt.Key_Tab || k === Qt.Key_Backtab) {
            stepSession(k === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        } else if (k === Qt.Key_Escape) {
            if (field === "name")
                auth.clearName();
            else
                auth.clearPassword(true);
            setMessage("", false);
            event.accepted = true;
        } else if (enter) {
            if (field === "name" && auth.userName.trim() !== "")
                auth.focusPassword();
            else
                submit();
            event.accepted = true;
        } else {
            if (event.text !== "")
                capsCheck();
            event.accepted = false;
        }
    }

    // --- power ---------------------------------------------------------------------------------------------
    property string leavingAction: ""
    function openDialog(which: string): void {
        if (greeter.current === "ready")
            dialog.open(which);
    }
    function leave(which: string): void {
        leavingAction = which;
        bridgeText = which === "reboot" ? "Rebooting…" : "Shutting down…";
        greeter.enter("leaving");
    }
    function power(): void {
        if (leavingAction === "reboot")
            link.reboot();
        else
            link.powerOff();
    }

    // --- timelines ---------------------------------------------------------------------------------------------
    component Reveal: ParallelAnimation {
        NumberAnimation { target: root; property: "paperShown"; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
        NumberAnimation { target: root; property: "uiShown"; to: 1; duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
        SequentialAnimation {
            PauseAnimation { duration: 100 }
            NumberAnimation { target: root; property: "usersIn"; to: 1; duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
        }
        SequentialAnimation {
            PauseAnimation { duration: 200 }
            NumberAnimation { target: root; property: "centerIn"; to: 1; duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
        }
        SequentialAnimation {
            PauseAnimation { duration: 300 }
            NumberAnimation { target: root; property: "authIn"; to: 1; duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
        }
    }

    // After the boot (~3.8 s): the band opens like a CRT line (dot, line, band) and closes back into a
    // line, the name enters scrambled on the dark, the paper and the panels come up under it, and
    // the name fades away.
    SequentialAnimation {
        id: introFull
        ScriptAction { script: root.bridgeMode = "dot" }
        PauseAnimation { duration: 200 }
        ScriptAction { script: root.bridgeMode = "line" }
        PauseAnimation { duration: 17 }
        ScriptAction { script: root.bridgeMode = "band" }
        PauseAnimation { duration: 1083 }
        ScriptAction { script: root.bridgeMode = "line" }
        PauseAnimation { duration: 17 }
        ScriptAction { script: root.bridgeMode = "off" }
        PauseAnimation { duration: 383 }
        ScriptAction { script: { root.titleShown = true; title.start(); } }
        PauseAnimation { duration: 1000 }
        ScriptAction { script: title.dark = true }
        ParallelAnimation {
            Reveal {}
            SequentialAnimation {
                PauseAnimation { duration: 600 }
                NumberAnimation { target: root; property: "titleOpacity"; to: 0; duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
            }
        }
        PauseAnimation { duration: 100 }
        ScriptAction { script: greeter.enter("ready") }
    }

    // After a logout or a user switch, or with intro=fade or reduced motion: the paper and the panels
    // fade in.
    SequentialAnimation {
        id: introFade
        Reveal {}
        ScriptAction { script: greeter.enter("ready") }
    }

    // The right password: "Welcome" comes in as the panels go.
    SequentialAnimation {
        id: welcomeSeq
        ParallelAnimation {
            SequentialAnimation {
                PauseAnimation { duration: 300 }
                NumberAnimation { target: root; property: "welcomeShown"; to: 1; duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
            }
            SequentialAnimation {
                PauseAnimation { duration: 500 }
                NumberAnimation { target: root; property: "uiShown"; to: 0; duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
            }
        }
    }

    // Reboot or Shut down confirmed: the screen goes dark, the band opens with "Rebooting…" or
    // "Shutting down…" and the SDDM is asked to act at once (research R10), so the boot theme's band
    // takes over; the band closes into a line after 1.5 s if the machine is still up.
    SequentialAnimation {
        id: leaveSeq
        ParallelAnimation {
            NumberAnimation { target: root; property: "paperShown"; to: 0; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
            NumberAnimation { target: root; property: "uiShown"; to: 0; duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: root.ease }
        }
        ScriptAction { script: { root.bridgeMode = "band"; root.power(); } }
        PauseAnimation { duration: 1500 }
        ScriptAction { script: root.bridgeMode = "line" }
        PauseAnimation { duration: 17 }
        ScriptAction { script: root.bridgeMode = "off" }
    }
    // If the machine never goes down (no permission, a hung unit), the login comes back.
    Timer {
        id: leaveSafety
        interval: 20000
        onTriggered: greeter.enter("intro")
    }

    // The wrong password: the auth panel tears 0.18 cqw (7 px at 4K) twice in 0.32 s, like the boot's
    // interference bands.
    QtObject {
        id: tear
        function start(): void {
            if (!Tokens.instant)
                tearSeq.restart();
        }
        function stop(): void {
            tearSeq.stop();
            root.authShift = 0;
        }
    }
    SequentialAnimation {
        id: tearSeq
        PropertyAction { target: root; property: "authShift"; value: -3.456 }
        PauseAnimation { duration: 80 }
        PropertyAction { target: root; property: "authShift"; value: 0 }
        PauseAnimation { duration: 80 }
        PropertyAction { target: root; property: "authShift"; value: -3.456 }
        PauseAnimation { duration: 80 }
        PropertyAction { target: root; property: "authShift"; value: 0 }
    }

    // --- the background: the shell's "Menu" scene (FR-002) -------------------------------------------------
    property real phase: Date.now() / 1000 % Tokens.wallpaper.cycle / Tokens.wallpaper.cycle
    Timer {
        interval: 125                            // the breathing is slow: 8 steps a second are plenty
        repeat: true
        running: !Tokens.instant && root.paperShown > 0
        onTriggered: root.phase = Date.now() / 1000 % Tokens.wallpaper.cycle / Tokens.wallpaper.cycle
    }

    Item {
        id: paper
        anchors.fill: parent
        opacity: root.paperShown
        visible: opacity > 0

        Rectangle {
            anchors.fill: parent
            color: Tokens.color.darkYellow
        }
        PaperDecor {
            anchors.fill: parent
            s: root.s
            phase: root.phase
            arcCycles: Tokens.wallpaper.cycle / Tokens.wallpaper.arcPeriod
            beamCycles: Tokens.wallpaper.cycle / Tokens.wallpaper.beamPeriod
        }
        Vignette {
            anchors.fill: parent
        }
    }

    Bridge {
        anchors.fill: parent
        visible: root.primary
        s: root.s
        mode: root.bridgeMode
        text: root.bridgeText
    }

    GlitchTitle {
        id: title
        width: parent.width
        y: Math.round(parent.height * 0.44)
        visible: root.primary && root.titleShown
        opacity: root.titleOpacity
        s: root.s
    }

    // --- the screen ---------------------------------------------------------------------------------------------
    // Always visible, only its opacity changes: the password field inside must keep the keyboard
    // focus during the entry, when the screen is still dark (FR-018).
    Item {
        id: ui
        anchors.fill: parent
        opacity: root.uiShown

        // a click on the paper gives the field its focus back
        MouseArea {
            anchors.fill: parent
            enabled: root.primary && !greeter.inert
            onClicked: root.focusField()
        }

        // the dotted rules: the top one where the bar's rule sits (y 48), the bottom one where the
        // "Menu + rules" scene has it (y 1012), both at the game's size (FR-003)
        Rule {
            y: root.u(48)
            width: parent.width
            s: root.s
            kind: "dotted"
            color: Qt.rgba(Tokens.color.darkGray.r, Tokens.color.darkGray.g, Tokens.color.darkGray.b, Tokens.wallpaper.ruleAlpha)
        }
        Rule {
            y: root.u(1012)
            width: parent.width
            s: root.s
            kind: "dotted"
            color: Qt.rgba(Tokens.color.darkGray.r, Tokens.color.darkGray.g, Tokens.color.darkGray.b, Tokens.wallpaper.ruleAlpha)
        }

        Item {
            id: panels
            anchors.fill: parent
            visible: root.primary

            // LOGIN -Authentication
            Item {
                x: root.u(65.28)
                y: root.u(119.04)
                height: root.u(65.28 * 1.55)
                width: head.width
                Label {
                    x: root.u(6.72)
                    y: head.y + root.u(6.72)
                    s: root.s
                    size: 65.28
                    spacing: 4.8
                    weight: Font.ExtraBold
                    color: Qt.rgba(126 / 255, 126 / 255, 116 / 255, 0.35)
                    text: "LOGIN"
                }
                Label {
                    id: head
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    size: 65.28
                    spacing: 4.8
                    weight: Font.ExtraBold
                    text: "LOGIN"
                }
                Label {
                    x: head.width + root.u(19.2)
                    anchors.baseline: head.baseline
                    s: root.s
                    size: 24.96
                    spacing: 1.92
                    text: "-Authentication"
                }
            }

            Users {
                visible: root.showUsers
                x: root.u(65.28)
                y: root.u(230.4) + (Tokens.instant ? 0 : (1 - root.usersIn) * root.u(19.2))
                width: root.u(422.4)
                opacity: root.usersIn
                s: root.s
                users: link.users
                current: root.sel
                interactive: !greeter.inert
                onPicked: index => {
                    root.select(index);
                    root.focusField();
                }
            }

            Clock {
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.u(288) + (Tokens.instant ? 0 : (1 - root.centerIn) * root.u(19.2))
                opacity: root.centerIn
                s: root.s
                mode: root.clockOption
            }

            Column {
                x: parent.width - root.u(65.28) - width + root.authShift * root.s
                y: root.u(230.4) + (Tokens.instant ? 0 : (1 - root.authIn) * root.u(19.2))
                width: root.u(499.2)
                opacity: root.authIn
                spacing: Tokens.px(Tokens.space.listItemGap, root.s)

                AuthCard {
                    id: auth
                    width: parent.width
                    s: root.s
                    otherUser: root.otherUser
                    message: root.message
                    error: root.messageError
                    onKeyPressed: (event, field) => root.handleKey(event, field)
                }
                Actions {
                    width: parent.width
                    s: root.s
                    session: root.sessionName
                    interactive: !greeter.inert
                    onSessionStep: d => {
                        root.stepSession(d);
                        root.focusField();
                    }
                    onReboot: root.openDialog("reboot")
                    onShutdown: root.openDialog("shutdown")
                }
            }

            KeyBar {
                y: root.u(1040)
                width: parent.width
                height: parent.height - y
                s: root.s
                hint: root.otherUser && auth.userName.trim() === "" ? "Enter a user name, then the password."
                                                                      : "Enter your password to proceed."
            }
        }
    }

    Welcome {
        id: welcome
        anchors.centerIn: parent
        visible: root.primary && opacity > 0
        opacity: root.welcomeShown
        s: root.s
    }

    ConfirmDialog {
        id: dialog
        anchors.fill: parent
        s: root.s
        onConfirmed: which => {
            dialog.close();
            root.leave(which);
        }
        onCancelled: {
            dialog.close();
            root.focusField();
        }
    }

    // While the login is not ready (the entry, the check, the welcome, leaving), nothing under this
    // reacts to the pointer (FR-021); a click during the entry cuts it (FR-018).
    MouseArea {
        anchors.fill: parent
        enabled: greeter.inert
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onPressed: {
            root.cut();
            root.focusField();
        }
    }
}
