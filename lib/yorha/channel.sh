# shellcheck shell=bash
# Where newer versions come from (spec 015, contracts/canal-publico.md): the origins, the channel,
# the newest version of the channel and the download of a version. Every origin answers the paths of
# GitHub's releases (<origin>/releases/latest/download/latest, <origin>/releases.atom,
# <origin>/releases/download/v<v>/<file>), so the same code reads GitHub, the lab and a mirror.
# Nothing is sent besides the request: no id, no installed version, curl's own User-Agent. curl's
# own errors stay quiet: an origin that does not answer is normal (a mirror down), and the callers
# say what failed.
#
# Shipped in lib/ and, by the release builder, also between the channel-core markers of install.sh,
# which has no lib/ before it downloads: keep it self-contained (bash, curl, coreutils; no other
# helper of lib/). Uses YORHA_NAME, YORHA_ORIGINS and YORHA_HOME when they are set.

# The origins in use, one per line, the main one first: YORHA_ORIGIN (one address, or several
# separated by spaces: a main one and its mirrors), or $YORHA_HOME/origins, or the release's own
# YORHA_ORIGINS. Trailing slashes are dropped.
yorha_origins() {
    local o list
    if [[ -n ${YORHA_ORIGIN:-} ]]; then
        read -ra list <<<"$YORHA_ORIGIN"
        for o in "${list[@]}"; do printf '%s\n' "${o%/}"; done
    elif [[ -n ${YORHA_HOME:-} && -s $YORHA_HOME/origins ]]; then
        while read -r o; do
            [[ -n $o && $o != '#'* ]] && printf '%s\n' "${o%/}"
        done < "$YORHA_HOME/origins"
    else
        # shellcheck disable=SC2153  # YORHA_ORIGINS comes from name.sh (or install.sh), set before this runs
        for o in "${YORHA_ORIGINS[@]}"; do printf '%s\n' "${o%/}"; done
    fi
}

# stable or testing: YORHA_CHANNEL, or $YORHA_HOME/channel, or stable. Anything else counts as stable.
yorha_channel() {
    local c=${YORHA_CHANNEL:-}
    [[ -z $c && -n ${YORHA_HOME:-} ]] && c=$(tr -d '[:space:]' < "$YORHA_HOME/channel" 2>/dev/null || true)
    [[ $c == testing ]] && echo testing || echo stable
}

yorha_valid_version() { [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; }

# The newest version of the channel on one origin ($1, channel $2), or nothing.
#   stable:  <origin>/releases/latest/download/latest (GitHub's "latest" never is a pre-release);
#   testing: the highest v<MAJOR.MINOR.PATCH> tag of <origin>/releases.atom, the stable ones included.
yorha_latest_at() {
    local o=$1 body v
    if [[ $2 == testing ]]; then
        body=$(curl -fsSL --max-time 20 "$o/releases.atom" 2>/dev/null) || return 1
        v=$(grep -oE '/releases/tag/v[0-9]+\.[0-9]+\.[0-9]+"' <<<"$body" | sed -E 's|.*/v||; s|"$||' | sort -V | tail -n 1 || true)
    else
        body=$(curl -fsSL --max-time 20 "$o/releases/latest/download/latest" 2>/dev/null) || return 1
        v=$(tr -d '[:space:]' <<<"$body")
    fi
    yorha_valid_version "$v" || return 1
    printf '%s\n' "$v"
}

# Prints "<v> <origin>": the newest version of the channel, from the first origin that answers with
# a valid one. Returns 1 when none did.
yorha_latest() {
    local o v ch
    ch=$(yorha_channel)
    while read -r o; do
        [[ -n $o ]] || continue
        v=$(yorha_latest_at "$o" "$ch") || continue
        printf '%s %s\n' "$v" "$o"
        return 0
    done < <(yorha_origins)
    return 1
}

# One value of a release manifest ($1, key=value lines) by its key ($2).
yorha_manifest_get() { sed -n "s/^$2=//p" "$1" | head -n 1; }

# Download version $1 into folder $2 (created): its package and the package's .sha256, both from the
# first origin that has both, then check the sum. With $4 (the origin that answered yorha_latest),
# that origin is tried first and then the others in order (the mirror rule, FR-018): every file of
# one version comes from one origin, and an origin that fails midway hands the whole version over to
# the next one. The package is the one the release's manifest names
# (<origin>/releases/download/v<v>/manifest, a fixed name: an older version finds the package of a
# newer one even under another product name, research R6); without a manifest (404), it is
# <name>-<v>.tar.gz, with $3 or YORHA_NAME as the name.
# Prints "<origin> <package> <name>": the origin used, the package's file in $2 and the product name
# of that version. Returns 1 when no origin had the files (or the manifest was unusable), 4 when the
# sum does not match (the files are removed).
yorha_fetch_release() {
    local v=$1 dir=$2 fallback=${3:-${YORHA_NAME:-}} first=${4:-} o code name pkg sum want mf
    yorha_valid_version "$v" || return 1
    mkdir -p "$dir" || return 1
    mf="$dir/manifest"
    while read -r o; do
        [[ -n $o ]] || continue
        rm -f "$mf"
        name=$fallback pkg="" want=""
        code=$(curl -fsSL --max-time 20 -o "$mf" -w '%{http_code}' "$o/releases/download/v$v/manifest" 2>/dev/null) || true
        if [[ $code == 200 && -s $mf ]]; then
            name=$(yorha_manifest_get "$mf" name)
            pkg=$(yorha_manifest_get "$mf" package)
            want=$(yorha_manifest_get "$mf" sha256)
            # A plain product name, and the package named after it (no path can come in).
            [[ $name =~ ^[a-z0-9][a-z0-9-]*$ && $pkg == "$name-$v.tar.gz" ]] || continue
            [[ $(yorha_manifest_get "$mf" version) == "$v" ]] || continue
        elif [[ $code == 404 && -n $fallback ]]; then
            pkg="$fallback-$v.tar.gz"
        else
            continue                    # the origin did not answer: the whole version from the next one
        fi
        rm -f "$dir/$pkg" "$dir/$pkg.sha256"
        curl -fsSL --max-time 20 -o "$dir/$pkg.sha256" "$o/releases/download/v$v/$pkg.sha256" 2>/dev/null || continue
        curl -fsSL -o "$dir/$pkg" "$o/releases/download/v$v/$pkg" 2>/dev/null || continue
        sum=$(sha256sum "$dir/$pkg" | cut -d' ' -f1)
        # The .sha256 decides; the manifest's sum, when there is one, has to agree with it.
        if [[ $sum != "$(awk 'NR == 1 { print $1 }' "$dir/$pkg.sha256")" || ${#sum} -ne 64 \
              || ( -n $want && $want != "$sum" ) ]]; then
            rm -f "$dir/$pkg" "$dir/$pkg.sha256" "$mf"
            return 4
        fi
        printf '%s %s %s\n' "$o" "$pkg" "$name"
        return 0
    done < <({ [[ -n $first ]] && printf '%s\n' "${first%/}"; yorha_origins; } | awk '!seen[$0]++')
    [[ -n $pkg ]] && rm -f "$dir/$pkg" "$dir/$pkg.sha256"
    rm -f "$mf"
    return 1
}
