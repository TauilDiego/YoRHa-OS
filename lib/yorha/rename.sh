# shellcheck shell=bash
# An update that changes the product's name (spec 015, FR-017, research R6, data-model.md "Depois de
# uma troca de nome"). Always run by the NEWER version, the only one that knows both names: by its
# `_finish-update`, and by its `rollback`, which makes the same move in the other direction (B to A,
# with A's variables), so a hyprland.lua line or keys of either name keep working. Sourced by bin/yorha after name.sh, common.sh and
# channel.sh; the YORHA_* variables are the ones of the version that runs.
#
# After a change from A to B:
#   ~/.local/share/B/                         everything that was in ~/.local/share/A/
#   ~/.local/share/A/renamed-to               name=, cmd=, bin=, home= of B (the supervisor follows it)
#   ~/.local/share/A/current/system/hypr/A.lua one line that loads B's file of the version in use, so
#                                             the person's hyprland.lua is never edited (principles II, III)
#   ~/.local/share/A/current/bin/<A cmd>      a link to B's command: the keys Hyprland already bound
#                                             (through A's file) keep working until the next login
#   ~/.local/state/A, ~/.config/A             links to B's folders
#   ~/.local/bin/<A cmd>                      a link to B's command (when the command changed)
#   ~/.local/state/B/renamed-from             name=, cmd=, pretty=, home=, state=, config=, version=, date=
#                                             of A (status, the shell's notice, rollback and uninstall read it)

# The name of the version in folder $1, from its own lib/yorha/name.sh, one value per line:
# name, cmd, pretty, home, state, config. Read in a subshell: nothing of the caller changes.
yorha_name_of() {
    [[ -f $1/lib/yorha/name.sh ]] || return 1
    # shellcheck source=/dev/null
    (source "$1/lib/yorha/name.sh" && printf '%s\n' "$YORHA_NAME" "$YORHA_CMD" "$YORHA_PRETTY" \
        "$YORHA_HOME" "$YORHA_STATE" "$YORHA_CONFIG")
}

# One value ($2) of a key=value file ($1), or nothing.
yorha_kv() { [[ -f $1 ]] && sed -n "s/^$2=//p" "$1" | head -n 1; }

# The Lua line that loads a product's file ($1, a path), written like the install's line.
yorha_dofile_line() {
    if [[ $1 == "$HOME"/* ]]; then printf 'pcall(dofile, os.getenv("HOME") .. "%s")' "${1#"$HOME"}"
    else printf 'pcall(dofile, "%s")' "$1"; fi
}

# A compatibility folder left by a change of name: renamed-to and no versions. Only those are removed
# by the functions below, never a real installation.
yorha_is_compat() { [[ -d $1 && ! -L $1 && -f $1/renamed-to && ! -e $1/versions ]]; }

# Move folder $1 to $2 and leave a link at $1 (state, config). Nothing to move is fine.
yorha_move_linked() {
    [[ -d $1 && ! -L $1 ]] || return 0
    [[ -L $2 ]] && rm -f "$2"
    [[ -e $2 ]] && yorha_fail "cannot move $1: $2 already exists; nothing else moved" 1
    mkdir -p "$(dirname "$2")"
    mv -T "$1" "$2"
    ln -sfn "$2" "$1"
}

# A to B: $1 = the folder of the version in use under the old name (A), still in A's home.
yorha_rename_forward() {
    local o oname ocmd opretty ohome ostate oconfig cur
    mapfile -t o < <(yorha_name_of "$1") || true
    ((${#o[@]} == 6)) || yorha_fail "cannot read the name of $1; nothing changed" 1
    oname=${o[0]} ocmd=${o[1]} opretty=${o[2]} ohome=${o[3]} ostate=${o[4]} oconfig=${o[5]}
    cur=$(basename "$1")
    [[ -d $ohome/versions ]] || yorha_fail "$ohome is not an installation; nothing changed" 1
    if yorha_is_compat "$YORHA_HOME"; then rm -rf "$YORHA_HOME"     # left by an older change of name
    elif [[ -e $YORHA_HOME || -L $YORHA_HOME ]]; then yorha_fail "$YORHA_HOME already exists; nothing changed" 1; fi
    yorha_say "$opretty is now $YORHA_PRETTY: moving $ohome to $YORHA_HOME"
    mv -T "$ohome" "$YORHA_HOME"
    yorha_move_linked "$ostate" "$YORHA_STATE"
    yorha_move_linked "$oconfig" "$YORHA_CONFIG"
    mkdir -p "$YORHA_STATE"
    # The old folder keeps the old line working.
    mkdir -p "$ohome/current/system/hypr" "$ohome/current/bin"
    printf '%s -- %s is now %s (spec 015, FR-017): this loads its file\n' \
        "$(yorha_dofile_line "$YORHA_HOME/current/system/hypr/$YORHA_NAME.lua")" "$oname" "$YORHA_NAME" \
        > "$ohome/current/system/hypr/$oname.lua"
    ln -sfn "$YORHA_HOME/current/bin/$YORHA_CMD" "$ohome/current/bin/$ocmd"
    printf 'name=%s\ncmd=%s\nbin=%s\nhome=%s\n' "$YORHA_NAME" "$YORHA_CMD" "$YORHA_BIN/$YORHA_CMD" "$YORHA_HOME" \
        > "$ohome/renamed-to.tmp" && mv -f "$ohome/renamed-to.tmp" "$ohome/renamed-to"
    printf 'name=%s\ncmd=%s\npretty=%s\nhome=%s\nstate=%s\nconfig=%s\nversion=%s\ndate=%s\n' \
        "$oname" "$ocmd" "$opretty" "$ohome" "$ostate" "$oconfig" "$cur" "$(date -Iseconds)" \
        > "$YORHA_STATE/renamed-from"
    mkdir -p "$YORHA_BIN"
    ln -sfn "$YORHA_HOME/current/bin/$YORHA_CMD" "$YORHA_BIN/$YORHA_CMD"
    [[ $ocmd != "$YORHA_CMD" ]] && ln -sfn "$YORHA_HOME/current/bin/$YORHA_CMD" "$YORHA_BIN/$ocmd"
    sync -f "$YORHA_HOME" 2>/dev/null || true
}

# What the person reads at the end of an update (or a rollback) that changed the name (A's values from
# renamed-from). $1 = whether their hyprland.lua already has the new line (0) or not (1).
yorha_rename_notes() {
    local f="$YORHA_STATE/renamed-from" oname ocmd
    oname=$(yorha_kv "$f" name) ocmd=$(yorha_kv "$f" cmd)
    [[ $ocmd != "$YORHA_CMD" ]] && yorha_say "the command is now $YORHA_CMD ($ocmd still works)"
    if [[ $1 != 0 ]]; then
        yorha_say "your hyprland.lua line keeps working; when you can, replace it with:"
        printf '\n    %s\n\n' "$(yorha_dofile_line "$YORHA_HOME/current/system/hypr/$YORHA_NAME.lua")"
    fi
    # Out of scope (R6): the optional boot and login module is not moved.
    if [[ -e /etc/sddm.conf.d/$oname.conf || -e /usr/share/plymouth/themes/$oname ]]; then
        yorha_say "the boot and login themes keep the name $oname and still work; to move them: $YORHA_CMD boot-login install"
    fi
}

# Uninstall: what a change of name left under the old name (the alias, the links, the compatibility
# folder, the old run folder). Read before the state goes.
yorha_rename_forget() {
    local f="$YORHA_STATE/renamed-from" oname ocmd ohome ostate oconfig
    [[ -s $f ]] || return 0
    oname=$(yorha_kv "$f" name) ocmd=$(yorha_kv "$f" cmd) ohome=$(yorha_kv "$f" home)
    ostate=$(yorha_kv "$f" state) oconfig=$(yorha_kv "$f" config)
    [[ -n $ocmd && $ocmd != "$YORHA_CMD" && -L $YORHA_BIN/$ocmd ]] && rm -f "$YORHA_BIN/$ocmd"
    [[ -n $ohome ]] && yorha_is_compat "$ohome" && rm -rf "$ohome"
    [[ -n $ostate && -L $ostate ]] && rm -f "$ostate"
    [[ -n $oconfig && -L $oconfig ]] && rm -f "$oconfig"
    [[ -n $oname ]] && rm -rf "${XDG_RUNTIME_DIR:-/tmp}/$oname"
    return 0
}

# status: after a change of name, the new line until the person's hyprland.lua has it. $1 = whether
# it has (0) or not (1), from the caller's has_include_line.
yorha_rename_status() {
    [[ -s $YORHA_STATE/renamed-from && $1 != 0 ]] || return 0
    printf '  hyprland:  renamed from %s; replace your line with: %s\n' "$(yorha_kv "$YORHA_STATE/renamed-from" name)" \
        "$(yorha_dofile_line "$YORHA_HOME/current/system/hypr/$YORHA_NAME.lua")"
}
