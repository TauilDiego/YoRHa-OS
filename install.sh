#!/usr/bin/env bash
# YoRHa-Shell installer (specs 014 and 015, contracts/cli.md). Run it as your user:
#   bash <(curl -fsSL https://github.com/TauilDiego/YoRHa-Shell/releases/latest/download/install.sh)
# Optional: YORHA_ORIGIN=<address> (the lab, a mirror; several, separated by spaces, are tried in
# order) in place of the release's own origins;
# YORHA_CHANNEL=stable|testing (default stable); YORHA_YES=1 answers yes to every question.
# Gets the newest version of the channel, checks its sha256, unpacks it next to nothing else
# (method D: ~/.local/share/<name>/versions/<v>), asks before installing the shell's dependencies,
# and hands over to that version's own `yorha _install`. It writes nothing outside the product's
# folders and never touches ~/.config/hypr: it prints the line to add there.
# Exit: 0 installed · 1 precondition, or no origin answered (nothing changed) · 2 already installed ·
# 3 a required dependency missing · 4 checksum mismatch.
set -euo pipefail
say() { printf 'yorha: %s\n' "$*"; }
fail() { printf 'yorha: %s\n' "$1" >&2; exit "${2:-1}"; }

# The release builder stamps these two from the release's lib/yorha/name.sh; the values here serve an
# unstamped copy (straight from the repository).
YORHA_NAME=yorha-shell
YORHA_DEFAULT_ORIGINS=(https://github.com/TauilDiego/YoRHa-Shell)

# The release builder puts the release's own lib/yorha/channel.sh between these markers. The copy
# here is that same file, so the installer also works unstamped.
# @@channel-core-begin
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
# @@channel-core-end

YORHA_ORIGINS=("${YORHA_DEFAULT_ORIGINS[@]}")
unset YORHA_HOME                     # the origins are YORHA_ORIGIN or the release's, never a leftover file
channel=${YORHA_CHANNEL:-stable}
[[ $EUID -ne 0 ]] || fail "run as your user, not root (sudo is asked only when needed)"
[[ -f /etc/arch-release ]] || fail "this installer is for Arch Linux"
command -v hyprctl >/dev/null || fail "Hyprland is not installed; install it first"
for c in curl tar sha256sum pacman; do command -v "$c" >/dev/null || fail "missing command: $c"; done
[[ $channel == stable || $channel == testing ]] || fail "YORHA_CHANNEL must be stable or testing, not '$channel'"
mapfile -t origins < <(yorha_origins)
((${#origins[@]})) || fail "no origin to install from"

latest=$(yorha_latest) || fail "no origin answered with a version (${origins[*]}); nothing installed"
v=${latest%% *}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/yorha-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
say "downloading version $v ($channel) from ${latest#* }"
rc=0
got=$(yorha_fetch_release "$v" "$tmp" "" "${latest#* }") || rc=$?
case $rc in
    0) ;;
    4) fail "checksum mismatch for $v; refusing" 4 ;;
    *) fail "download of $v failed; nothing installed" ;;
esac
mkdir "$tmp/v"
pkg=$(cut -d' ' -f2 <<<"$got")      # the package the release's manifest names
say "checksum ok ($pkg, from ${got%% *})"
tar -xzf "$tmp/$pkg" -C "$tmp/v" --strip-components=1

# From here on the names come from the version itself (lib/yorha/name.sh, FR-019). Its lib/ only
# exists once downloaded, so shellcheck cannot follow it (SC1091).
YORHA_ROOT="$tmp/v"
# shellcheck disable=SC1091
source "$YORHA_ROOT/lib/yorha/name.sh"
# shellcheck disable=SC1091
source "$YORHA_ROOT/lib/yorha/common.sh"
# shellcheck disable=SC1091
source "$YORHA_ROOT/lib/yorha/deps.sh"
if [[ -n $(yorha_current) ]]; then
    yorha_say "$YORHA_PRETTY $(yorha_current) is already installed in $YORHA_HOME; to get newer versions: $YORHA_CMD update"
    exit 2
fi
yorha_deps_ensure "$YORHA_ROOT/system/deps" || exit 3
yorha_prepare "$YORHA_ROOT"

mkdir -p "$YORHA_HOME/versions"
rm -rf "$YORHA_HOME/versions/.$v.part"
mv -T "$tmp/v" "$YORHA_HOME/versions/.$v.part"
mv -T "$YORHA_HOME/versions/.$v.part" "$YORHA_HOME/versions/$v"
printf '%s\n' "${origins[@]}" > "$YORHA_HOME/origins"
echo "$channel" > "$YORHA_HOME/channel"
rm -rf "$tmp"                        # exec skips the EXIT trap
exec "$YORHA_HOME/versions/$v/bin/$YORHA_CMD" _install
