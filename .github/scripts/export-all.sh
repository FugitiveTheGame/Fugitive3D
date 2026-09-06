#!/usr/bin/env bash
# Imports the project and exports every release preset headlessly.
#
#   GODOT_BIN=/path/to/godot .github/scripts/export-all.sh
#
# Environment:
#   GODOT_BIN    Godot editor binary (required)
#   RUN_TESTS    run the gdUnit4 suites before exporting (default true)
#   TESTS_GATE   a test failure aborts the export (default false)
#
# Android exports additionally need JAVA_HOME and ANDROID_HOME set before the
# first Godot invocation in this environment: Godot copies them into its editor
# settings on first launch and does not look again.
set -euo pipefail

: "${GODOT_BIN:?GODOT_BIN is required}"
RUN_TESTS="${RUN_TESTS:-true}"
TESTS_GATE="${TESTS_GATE:-false}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
mkdir -p export
touch export/.gdignore

log() { echo "==> $*"; }

godot() {
	"$GODOT_BIN" --headless --path "$ROOT" "$@"
}

# The first pass on a fresh checkout builds the GDExtension list and the
# uid/class caches, and scenes typed against extension classes (opus, the
# OpenXR vendors) can log errors before that exists. The second pass is cheap
# and has to be clean.
log "importing (first pass)"
godot --import || echo "first import pass reported errors; running again"
log "importing (second pass)"
godot --import
imported="$(find .godot/imported -type f 2>/dev/null | wc -l)"
if (( imported < 100 )); then
	echo "import produced only $imported files under .godot/imported" >&2
	exit 1
fi
log "imported $imported files"

if [[ "$RUN_TESTS" == "true" ]]; then
	log "running gdUnit4 suites"
	if bash addons/gdUnit4/runtest.sh --godot_binary "$GODOT_BIN" \
		--headless --ignoreHeadlessMode -a res://test; then
		log "tests passed"
	elif [[ "$TESTS_GATE" == "true" ]]; then
		echo "::error::gdUnit4 tests failed"
		exit 1
	else
		echo "::warning::gdUnit4 tests failed (not gating this release)"
	fi
fi

# Godot exits non-zero on export failure, but a few keystore and template
# problems only print, so also look for the phrases they use.
FATAL_PATTERNS='Export failed|Failed to export|Invalid filename|No export template found|incorrectly configured|Username and/or Password is invalid|must be configured|A valid Java SDK path|A valid Android SDK path|Building of Android project failed'

export_preset() {
	local name=$1 out=$2
	shift 2
	local dir logfile
	dir="$(dirname "$out")"
	logfile="export/$(basename "$out").log"

	log "exporting '$name' -> $out"
	rm -rf "$dir"
	mkdir -p "$dir"
	set +e
	godot "$@" --export-release "$name" "$out" 2>&1 | tee "$logfile"
	local status=${PIPESTATUS[0]}
	set -e
	if (( status != 0 )); then
		echo "Godot exited with $status exporting '$name'" >&2
		exit 1
	fi
	if grep -qE "$FATAL_PATTERNS" "$logfile"; then
		echo "export log for '$name' contains a fatal error:" >&2
		grep -E "$FATAL_PATTERNS" "$logfile" >&2
		exit 1
	fi
	if [[ ! -s "$out" ]]; then
		echo "'$name' produced no output at $out" >&2
		exit 1
	fi
	log "ok: $(du -h "$out" | cut -f1) $out"
}

# Desktop first: fast, and any import or pck problem shows up before the slow
# gradle builds. The Google Play preset is last because it is the one most
# likely to need a second look.
export_preset "Client Flat - Windows"             export/client/flat/windows/Fugitive3D_Client_Flat_Windows.exe
export_preset "Client Flat - Linux/X11"           export/client/flat/linux/Fugitive3D_Client_Flat_Linux.x86_64
export_preset "Client VR - Windows Desktop"       export/client/vr/windows/Fugitive3D_Client_VR_Windows.exe
export_preset "Client VR - Oculus Desktop"        export/client/vr/oculus-rift/Fugitive3D_Client_VR_Oculus_Windows.exe
export_preset "Server - Windows"                  export/server/windows/Fugitive3D_Server_Windows.exe
export_preset "Server - Linux"                    export/server/linux/Fugitive3D_Server_Linux.x86_64
export_preset "Client Flat - Android"             export/client/flat/android/Fugitive3D_Client_Flat_Android.apk
export_preset "Client VR - Oculus Quest"          export/client/vr/quest/Fugitive3D_Client_VR_Quest.apk --install-android-build-template
export_preset "Client Flat - Android Google Play" export/client/flat/android/google_play/Fugitive3D_Client_Flat_Android_GP.aab --install-android-build-template

log "all presets exported"
