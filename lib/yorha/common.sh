# shellcheck shell=bash
# Shared helpers of the yorha CLI (spec 014), carried over from the method D prototype of spec 005
# (lab/u2/comum/yorha-common.sh). Shipped inside every version, so each version runs its own copy.
# Sourced by bin/yorha after lib/yorha/name.sh; YORHA_ROOT (the version's folder) is set by the caller.

yorha_say() { printf '%s: %s\n' "$YORHA_CMD" "$*"; }
yorha_fail() { printf '%s: %s\n' "$YORHA_CMD" "$*" >&2; exit "${2:-1}"; }

# "y"/"s" is yes; anything else, or no terminal to ask on, is no. YORHA_YES=1 answers yes to all
# (automation and the lab's checks).
yorha_ask() {
    local a
    [[ ${YORHA_YES:-} == 1 ]] && { yorha_say "$* [y/N] y (YORHA_YES=1)"; return 0; }
    [[ -t 0 ]] || return 1
    read -r -p "$YORHA_CMD: $* [y/N] " a || return 1
    [[ $a == [yYsS]* ]]
}

yorha_version_of() { tr -d '[:space:]' < "$1/VERSION" 2>/dev/null || echo none; }

# The version in use ("" when nothing is installed).
yorha_current() { [[ -L $YORHA_HOME/current ]] && basename "$(readlink "$YORHA_HOME/current")" || true; }

# Fresh install: every migration that ships with the version counts as done (like Omarchy).
yorha_mark_migrations() {
    local m
    mkdir -p "$YORHA_STATE/migrations"
    for m in "$1"/migrations/*.sh; do [[ -e $m ]] && touch "$YORHA_STATE/migrations/$(basename "$m")"; done
    return 0
}

# Run the pending migrations of a version for this user, in order. The first failure stops the
# queue. $1 = the version's folder, $2 = the version the state comes from.
yorha_migrate() {
    local root=$1 from=${2:-unknown} m name ran=0
    mkdir -p "$YORHA_STATE/migrations"
    for m in "$root"/migrations/*.sh; do
        [[ -e $m ]] || continue
        name=$(basename "$m")
        [[ -e $YORHA_STATE/migrations/$name ]] && continue
        if ! YORHA_STATE="$YORHA_STATE" YORHA_CONFIG="$YORHA_CONFIG" YORHA_FROM="$from" bash -- "$m"; then
            printf '%s: migration %s failed; the queue stops here (yorha rollback goes back)\n' "$YORHA_CMD" "$name" >&2
            return 1
        fi
        touch "$YORHA_STATE/migrations/$name"
        sync -f "$YORHA_STATE/migrations/$name" 2>/dev/null || true
        yorha_say "migration $name done"
        ran=$((ran + 1))
    done
    yorha_version_of "$root" > "$YORHA_STATE/last-version"
    return 0
}

# Copy the user's state (without older copies) before an update touches it; prints the copy's folder.
yorha_backup_state() {
    local dest="$YORHA_STATE/backups/$1"
    rm -rf "$dest" && mkdir -p "$dest"
    (cd "$YORHA_STATE" && find . -mindepth 1 -maxdepth 1 ! -name backups -exec cp -a -t "$dest" {} +)
    printf '%s\n' "$dest"
}

# Point "current" (and the command) at versions/$1, atomically; remember the one it replaces.
yorha_switch() {
    local v=$1 old
    old=$(yorha_current)
    ln -sfn "versions/$v" "$YORHA_HOME/.current.tmp"
    mv -Tf "$YORHA_HOME/.current.tmp" "$YORHA_HOME/current"
    sync -f "$YORHA_HOME" 2>/dev/null || true
    [[ -n $old && $old != "$v" ]] && echo "$old" > "$YORHA_HOME/previous"
    mkdir -p "$YORHA_BIN"
    ln -sfn "$YORHA_HOME/current/bin/$YORHA_CMD" "$YORHA_BIN/$YORHA_CMD"
}

# Keep the newest $YORHA_KEEP versions, never the one in use; drop leftovers of interrupted unpacks.
yorha_prune() {
    local cur v
    cur=$(yorha_current)
    find "$YORHA_HOME/versions" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\n' | sort -V \
        | head -n -"$YORHA_KEEP" | while read -r v; do [[ $v == "$cur" ]] || rm -rf "${YORHA_HOME:?}/versions/$v"; done
    find "$YORHA_HOME/versions" -mindepth 1 -maxdepth 1 -name '.*.part' -exec rm -rf {} +
    rm -rf "$YORHA_HOME/downloads"
}

# Finish a freshly unpacked version before it goes in use: the shell's shaders are compiled where
# the UI runs (shell/shaders/build.sh needs qsb, from qt6-shadertools, a required dependency).
yorha_prepare() {
    "$1/shell/shaders/build.sh" >/dev/null || yorha_say "the shaders of $(yorha_version_of "$1") did not build; wallpaper transitions fall back to a crossfade"
}
