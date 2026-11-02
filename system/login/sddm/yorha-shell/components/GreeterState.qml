import QtQuick

// The greeter's single state (spec 011, research R5, data-model.md "Estado do greeter"):
//   intro     the entry after the boot (full) or after a logout (fade); keys and clicks cut it
//   ready     the login at rest (the confirmation dialog is a sub-state of it)
//   checking  the password went to the SDDM; the field and Enter wait for its answer
//   welcome   the password was right; the session is starting
//   leaving   Reboot or Shut down was confirmed
// Each state owns its animations and timers (`owned`, filled by the screen). enter() stops every one
// the state it leaves owns before the new state starts, so no animation ever runs over another one
// (owner, 29.10), and logs `yorha-login: state=<state>` for the lab's checks. A transition the table
// does not allow is refused and changes nothing.
QtObject {
    id: root

    property string current: ""
    // Only `ready` takes the pointer (FR-021).
    readonly property bool inert: current !== "ready"
    // state → list of objects with stop() (animations, timers, components)
    property var owned: ({})
    property bool logging: true

    readonly property var allowed: ({
        "": ["intro", "ready"],
        "intro": ["ready"],
        "ready": ["checking", "leaving"],
        "checking": ["ready", "welcome"],
        "welcome": [],
        "leaving": ["intro"]
    })

    signal entered(string state, string previous)

    function stopAll(state: string): void {
        const list = owned[state] ?? [];
        for (let i = 0; i < list.length; i++)
            list[i].stop();
    }

    function can(next: string): bool {
        return (allowed[current] ?? []).indexOf(next) >= 0;
    }

    function enter(next: string): bool {
        if (!can(next))
            return false;
        const previous = current;
        stopAll(previous);
        current = next;
        if (logging)
            console.log("yorha-login: state=" + next);
        entered(next, previous);
        return true;
    }
}
