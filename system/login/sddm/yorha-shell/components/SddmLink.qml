// The conversation with the SDDM: the user and session models, the last user and session, logging
// in and the answer, reboot and power off.
//
// The way it talks to the SDDM follows Qylock's Main.qml (doLogin(), the userModel/sessionModel
// reads by role and the loginFailed connection): Qylock, by Darkkal44,
// https://github.com/Darkkal44/qylock, licensed under the GNU General Public License v3.0.
// This file is distributed under the GPL-3.0 as well; the rest of the theme is AGPL-3.0-or-later,
// which may be combined with it (GPLv3 §13). See CREDITS.md.
import QtQuick

Item {
    id: root

    // [{ name, label }]: the listable users (label = the real name when there is one).
    property var users: []
    // [name]: the installed sessions, in the SDDM's order (the index is what sddm.login takes).
    property var sessions: []

    readonly property bool present: typeof sddm !== "undefined"
    readonly property int lastUser: users.length > 0 && typeof userModel !== "undefined"
        && userModel.lastIndex >= 0 && userModel.lastIndex < users.length ? userModel.lastIndex : 0
    // A remembered session that no longer exists falls back to the first one.
    readonly property int lastSession: typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0
        && sessionModel.lastIndex < sessions.length ? sessionModel.lastIndex : 0

    signal failed()
    signal info(string message)
    signal succeeded()

    function read(model: var, row: int, role: int): string {
        const v = model.data(model.index(row, 0), role);
        return v === undefined || v === null ? "" : String(v);
    }

    function load(): void {
        const u = [];
        if (typeof userModel !== "undefined") {
            for (let i = 0; i < userModel.rowCount(); i++) {
                const name = read(userModel, i, Qt.UserRole + 1);       // NameRole
                const real = read(userModel, i, Qt.UserRole + 2).trim(); // RealNameRole
                u.push({ name: name, label: real !== "" ? real : name });
            }
        }
        const s = [];
        if (typeof sessionModel !== "undefined") {
            for (let i = 0; i < sessionModel.rowCount(); i++)
                s.push(read(sessionModel, i, Qt.UserRole + 4));         // NameRole
        }
        users = u;
        sessions = s;
    }

    function login(name: string, password: string, session: int): void {
        if (present)
            sddm.login(name, password, session);
    }
    function reboot(): void {
        if (present)
            sddm.reboot();
    }
    function powerOff(): void {
        if (present)
            sddm.powerOff();
    }

    Component.onCompleted: load()

    Connections {
        target: root.present ? sddm : null
        function onLoginFailed(): void { root.failed(); }
        // PAM's own words, e.g. pam_faillock's "The account is locked…": shown instead of the plain failure
        function onInformationMessage(message: string): void { root.info(message); }
        function onLoginSucceeded(): void { root.succeeded(); }
    }
    Connections {
        target: typeof userModel !== "undefined" ? userModel : null
        function onModelReset(): void { Qt.callLater(root.load); }
        function onRowsInserted(): void { Qt.callLater(root.load); }
        function onRowsRemoved(): void { Qt.callLater(root.load); }
    }
    Connections {
        target: typeof sessionModel !== "undefined" ? sessionModel : null
        function onModelReset(): void { Qt.callLater(root.load); }
        function onRowsInserted(): void { Qt.callLater(root.load); }
        function onRowsRemoved(): void { Qt.callLater(root.load); }
    }
}
