#!/usr/bin/env bash
# YoRHa-Shell installer (specs 014 and 015, contracts/cli.md). Run it as your user:
#   bash <(curl -fsSL https://github.com/TauilDiego/YoRHa-Shell/releases/latest/download/install.sh)
# Optional: YORHA_ORIGIN=<address> (the lab, a mirror) in place of the release's own origins;
# YORHA_CHANNEL=stable|testing (default stable); YORHA_YES=1 answers yes to every question.
# Gets the newest version of the channel, checks its sha256, unpacks it next to nothing else
# (method D: ~/.local/share/<name>/versions/<v>), asks before installing the shell's dependencies,
# and hands over to that version's own `yorha _install`. It writes nothing outside the product's
# folders and never touches ~/.config/hypr: it prints the line to add there.
# Exit: 0 installed · 1 precondition, or no origin answered (nothing changed) · 2 already installed ·
# 3 a required dependency missing · 4 checksum mismatch.
set -euo pipefail
say() { printf 'yorha: %s\n' "$*"; }
fail() { printf 'yorha: %s\n' "$*" >&2; exit "${2:-1}"; }

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
# Nothing is sent besides the request: no id, no installed version, curl's own User-Agent.
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
        body=$(curl -fsSL --max-time 20 "$o/releases.atom") || return 1
        v=$(grep -oE '/releases/tag/v[0-9]+\.[0-9]+\.[0-9]+"' <<<"$body" | sed -E 's|.*/v||; s|"$||' | sort -V | tail -n 1 || true)
    else
        body=$(curl -fsSL --max-time 20 "$o/releases/latest/download/latest") || return 1
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
        curl -fsSL --max-time 20 -o "$dir/$pkg.sha256" "$o/releases/download/v$v/$pkg.sha256" || continue
        curl -fsSL -o "$dir/$pkg" "$o/releases/download/v$v/$pkg" || continue
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
# @@channel-core-end

YORHA_ORIGINS=("${YORHA_DEFAULT_ORIGINS[@]}")
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
yorha_fetch_release "$v" "$tmp" >/dev/null || rc=$?
case $rc in
    0) ;;
    4) fail "checksum mismatch for $v; refusing" 4 ;;
    *) fail "download of $v failed; nothing installed" ;;
esac
mkdir "$tmp/v"
tar -xzf "$tmp/$YORHA_NAME-$v.tar.gz" -C "$tmp/v" --strip-components=1

# From here on the names come from the version itself (lib/yorha/name.sh, FR-019).
YORHA_ROOT="$tmp/v"
source "$YORHA_ROOT/lib/yorha/name.sh"
source "$YORHA_ROOT/lib/yorha/common.sh"
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
