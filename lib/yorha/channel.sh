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

# The origins in use, one per line, the main one first: YORHA_ORIGIN, or $YORHA_HOME/origins, or the
# release's own YORHA_ORIGINS. Trailing slashes are dropped.
yorha_origins() {
    local o
    if [[ -n ${YORHA_ORIGIN:-} ]]; then
        printf '%s\n' "${YORHA_ORIGIN%/}"
    elif [[ -n ${YORHA_HOME:-} && -s $YORHA_HOME/origins ]]; then
        while read -r o; do
            [[ -n $o && $o != '#'* ]] && printf '%s\n' "${o%/}"
        done < "$YORHA_HOME/origins"
    else
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

# Download version $1 into folder $2 (created): <name>-<v>.tar.gz and its .sha256, both from the
# first origin that has both, then check the sum. Prints the origin used. Returns 1 when no origin
# had both files, 4 when the sum does not match (the files are removed). $3: the package name, when
# it is not YORHA_NAME.
yorha_fetch_release() {
    local v=$1 dir=$2 name=${3:-${YORHA_NAME:-}} o pkg sum want
    [[ -n $name ]] && yorha_valid_version "$v" || return 1
    pkg="$name-$v.tar.gz"
    mkdir -p "$dir" || return 1
    while read -r o; do
        [[ -n $o ]] || continue
        rm -f "$dir/$pkg" "$dir/$pkg.sha256"
        curl -fsSL --max-time 20 -o "$dir/$pkg.sha256" "$o/releases/download/v$v/$pkg.sha256" 2>/dev/null || continue
        curl -fsSL -o "$dir/$pkg" "$o/releases/download/v$v/$pkg" 2>/dev/null || continue
        want=$(awk 'NR == 1 { print $1 }' "$dir/$pkg.sha256")
        sum=$(sha256sum "$dir/$pkg" | cut -d' ' -f1)
        if [[ ${#want} -ne 64 || $sum != "$want" ]]; then
            rm -f "$dir/$pkg" "$dir/$pkg.sha256"
            return 4
        fi
        printf '%s\n' "$o"
        return 0
    done < <(yorha_origins)
    rm -f "$dir/$pkg" "$dir/$pkg.sha256"
    return 1
}
