# shellcheck shell=bash
# The shell's system dependencies (spec 014, FR-002, research R3): which are missing, and installing
# them only after the person says yes. Sourced after name.sh and common.sh.

# Missing packages of the manifest ($1), of one kind ($2: required|optional), one per line.
yorha_deps_missing() {
    local pkgs
    mapfile -t pkgs < <(awk -v k="$2" '!/^[[:space:]]*(#|$)/ && $2 == k { print $1 }' "$1")
    ((${#pkgs[@]})) || return 0
    pacman -T -- "${pkgs[@]}" || true
}

# What a package is for, from the manifest.
yorha_deps_why() { awk -v p="$2" '$1 == p { $1 = ""; $2 = ""; sub(/^ +/, ""); print }' "$1"; }

# Check the manifest ($1) and offer to install what is missing. Returns 3 when a required package is
# still missing (refused, or the install failed); missing optional ones only warn.
yorha_deps_ensure() {
    local manifest=$1 req opt p want=()
    mapfile -t req < <(yorha_deps_missing "$manifest" required)
    mapfile -t opt < <(yorha_deps_missing "$manifest" optional)
    if ((${#req[@]} + ${#opt[@]} == 0)); then
        yorha_say "all dependencies are installed"
        return 0
    fi
    yorha_say "missing system packages:"
    for p in "${req[@]}"; do printf '  %-26s required  %s\n' "$p" "$(yorha_deps_why "$manifest" "$p")"; done
    for p in "${opt[@]}"; do printf '  %-26s optional  %s\n' "$p" "$(yorha_deps_why "$manifest" "$p")"; done
    want=("${req[@]}" "${opt[@]}")
    if yorha_ask "install them with: sudo pacman -S --needed ${want[*]}?"; then
        if ! sudo pacman -S --needed --noconfirm -- "${want[@]}"; then
            # A stale package database gives 404s; the Arch way is a full upgrade, never -Sy alone.
            yorha_say "pacman could not install them (an old package database is the usual cause)"
            if yorha_ask "update the whole system and install them: sudo pacman -Syu --needed ${want[*]}?"; then
                sudo pacman -Syu --needed --noconfirm -- "${want[@]}" || true
            fi
        fi
    fi
    mapfile -t req < <(yorha_deps_missing "$manifest" required)
    if ((${#req[@]})); then
        yorha_say "still missing, and the shell does not start without them: ${req[*]}"
        return 3
    fi
    mapfile -t opt < <(yorha_deps_missing "$manifest" optional)
    for p in "${opt[@]}"; do yorha_say "without $p: $(yorha_deps_why "$manifest" "$p") will not work"; done
    return 0
}
