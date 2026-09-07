#!/usr/bin/env bash
# Stamps the release version into export_presets.cfg.
#
#   VERSION=0.8.0 VERSION_CODE=800 .github/scripts/set-version.sh
#
# Android presets get version/code and version/name; Windows presets get the
# four-part file and product version Godot expects. GAME_VERSION in
# common/UserData.gd is the network protocol number and is deliberately not
# derived from the tag.
set -euo pipefail

: "${VERSION:?VERSION (X.Y.Z) is required}"
: "${VERSION_CODE:?VERSION_CODE (integer) is required}"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "VERSION must be X.Y.Z, got '$VERSION'" >&2
	exit 1
fi
if [[ ! "$VERSION_CODE" =~ ^[0-9]+$ ]]; then
	echo "VERSION_CODE must be an integer, got '$VERSION_CODE'" >&2
	exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PRESETS="$ROOT/export_presets.cfg"

# [^\r]* rather than .* so a CRLF checkout keeps its line endings intact.
sed -i -E \
	-e "s|^(version/code=)[^\r]*|\1${VERSION_CODE}|" \
	-e "s|^(version/name=)[^\r]*|\1\"${VERSION}\"|" \
	-e "s|^(application/file_version=)[^\r]*|\1\"${VERSION}.0\"|" \
	-e "s|^(application/product_version=)[^\r]*|\1\"${VERSION}.0\"|" \
	"$PRESETS"

# A preset rename or key change that breaks the patterns above must fail here
# rather than ship a build with stale version numbers.
expect() {
	local pattern=$1 want=$2 what=$3 got
	got="$(grep -cE "$pattern" "$PRESETS" || true)"
	if [[ "$got" != "$want" ]]; then
		echo "expected $want $what lines in export_presets.cfg, found $got" >&2
		exit 1
	fi
}
expect "^version/code=${VERSION_CODE}\r?$" 3 "Android version/code"
expect "^version/name=\"${VERSION}\"\r?$" 3 "Android version/name"
expect "^application/file_version=\"${VERSION}.0\"\r?$" 4 "Windows file_version"
expect "^application/product_version=\"${VERSION}.0\"\r?$" 4 "Windows product_version"

echo "export_presets.cfg stamped with ${VERSION} (code ${VERSION_CODE})"
