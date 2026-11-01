#!/usr/bin/env bash
# YoRHa-OS installer (spec 014, contracts/cli.md). Run it as your user:
#   YORHA_OS_CHANNEL=<url> bash <(curl -fsSL <url>/install.sh)
# Downloads the newest version from the channel, checks its sha256, unpacks it next to nothing else
# (method D: ~/.local/share/<name>/versions/<v>), asks before installing the shell's dependencies,
# and hands over to that version's own `yorha _install`. It writes nothing outside the product's
# folders and never touches ~/.config/hypr: it prints the line to add there.
# Exit: 0 installed · 1 precondition (nothing changed) · 2 already installed · 3 a required
# dependency missing · 4 checksum mismatch.
set -euo pipefail
say() { printf 'yorha: %s\n' "$*"; }
fail() { printf 'yorha: %s\n' "$*" >&2; exit "${2:-1}"; }

channel=${YORHA_OS_CHANNEL:-}
[[ $EUID -ne 0 ]] || fail "run as your user, not root (sudo is asked only when needed)"
[[ -f /etc/arch-release ]] || fail "this installer is for Arch Linux"
command -v hyprctl >/dev/null || fail "Hyprland is not installed; install it first"
for c in curl tar sha256sum pacman; do command -v "$c" >/dev/null || fail "missing command: $c"; done
[[ -n $channel ]] || fail "set YORHA_OS_CHANNEL to the address of the versions"
channel=${channel%/}

v=$(curl -fsS "$channel/latest" | tr -d '[:space:]') || fail "could not reach $channel; nothing installed"
[[ $v =~ ^[0-9]+(\.[0-9]+)+$ ]] || fail "bad version '$v' from $channel"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/yorha-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
say "downloading version $v from $channel"
for f in "yorha-os-$v.tar.gz" "yorha-os-$v.tar.gz.sha256"; do
    curl -fsS -o "$tmp/$f" "$channel/$f" || fail "download of $f failed; nothing installed"
done
(cd "$tmp" && sha256sum --quiet -c "yorha-os-$v.tar.gz.sha256") || fail "checksum mismatch for $v; refusing" 4
mkdir "$tmp/v"
tar -xzf "$tmp/yorha-os-$v.tar.gz" -C "$tmp/v" --strip-components=1

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
echo "$channel" > "$YORHA_HOME/channel"
rm -rf "$tmp"                        # exec skips the EXIT trap
exec "$YORHA_HOME/versions/$v/bin/$YORHA_CMD" _install
