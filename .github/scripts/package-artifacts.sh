#!/usr/bin/env bash
# Turns the export/ tree into release assets under dist/ and checks them.
#
#   VERSION=0.8.0 VERSION_CODE=800 .github/scripts/package-artifacts.sh
#
# Desktop presets export with embed_pck=false, so each one is a directory
# (binary, .pck, GDExtension libraries) and ships as a zip. Windows builds also
# get the MSVC runtime DLLs from extras/win-dependencies. Android outputs are
# copied as they are.
set -euo pipefail

: "${VERSION:?VERSION (X.Y.Z) is required}"
VERSION_CODE="${VERSION_CODE:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
DIST="$ROOT/dist"
rm -rf "$DIST"
mkdir -p "$DIST"

log() { echo "==> $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }

WIN_DIRS=(export/client/flat/windows export/client/vr/windows export/client/vr/oculus-rift export/server/windows)
for d in "${WIN_DIRS[@]}"; do
	cp extras/win-dependencies/vcruntime140.dll extras/win-dependencies/vcruntime140_1.dll "$d/"
done

# zip -r keeps the executable bit on the Linux binaries; archive contents sit
# at the root, matching what itch users already have installed. 7-Zip is the
# fallback for local runs on Windows, where there is no executable bit anyway.
ZIP_TOOL=""
if command -v zip > /dev/null 2>&1; then
	ZIP_TOOL=zip
elif command -v 7z > /dev/null 2>&1; then
	ZIP_TOOL=7z
elif [[ -x "/c/Program Files/7-Zip/7z.exe" ]]; then
	ZIP_TOOL="/c/Program Files/7-Zip/7z.exe"
else
	fail "neither zip nor 7z is available"
fi

zipdir() {
	local src=$1 name=$2
	local out="$DIST/${name}_v${VERSION}.zip"
	log "packing $src -> $(basename "$out")"
	if [[ "$ZIP_TOOL" == "zip" ]]; then
		(cd "$src" && zip -qr "$out" . -x '*.log' '*.idsig')
	else
		(cd "$src" && "$ZIP_TOOL" a -tzip -bso0 -bsp0 "$out" . '-xr!*.log' '-xr!*.idsig')
	fi
}

zipdir export/client/flat/windows    Fugitive3D_Client_Flat_Windows
zipdir export/client/flat/linux      Fugitive3D_Client_Flat_Linux
zipdir export/client/vr/windows      Fugitive3D_Client_VR_Windows
zipdir export/client/vr/oculus-rift  Fugitive3D_Client_VR_Oculus_Windows
zipdir export/server/windows         Fugitive3D_Server_Windows
zipdir export/server/linux           Fugitive3D_Server_Linux

cp export/client/flat/android/Fugitive3D_Client_Flat_Android.apk                "$DIST/Fugitive3D_Client_Flat_Android_v${VERSION}.apk"
cp export/client/vr/quest/Fugitive3D_Client_VR_Quest.apk                        "$DIST/Fugitive3D_Client_VR_Quest_v${VERSION}.apk"
cp export/client/flat/android/google_play/Fugitive3D_Client_Flat_Android_GP.aab "$DIST/Fugitive3D_Client_Flat_Android_GP_v${VERSION}.aab"

log "checking archives"

# Every desktop zip: exactly one main binary, exactly one pck, both
# GDExtension libraries, and the runtime DLLs on Windows.
check_zip() {
	local zip=$1 kind=$2 listing
	listing="$(unzip -Z1 "$zip")"
	case "$kind" in
		windows)
			[[ "$(grep -c '\.exe$' <<<"$listing")" == 2 ]] || fail "$zip: expected the exe and its .console.exe"
			grep -q '\.console\.exe$' <<<"$listing" || fail "$zip: missing the console wrapper"
			grep -q '^vcruntime140\.dll$' <<<"$listing" || fail "$zip: missing vcruntime140.dll"
			grep -q '^vcruntime140_1\.dll$' <<<"$listing" || fail "$zip: missing vcruntime140_1.dll"
			grep -q '^libgodotopus.*\.dll$' <<<"$listing" || fail "$zip: missing the opus GDExtension"
			grep -q '^libgodotopenxrvendors.*\.dll$' <<<"$listing" || fail "$zip: missing the OpenXR vendors GDExtension"
			;;
		linux)
			[[ "$(grep -c '\.x86_64$' <<<"$listing")" == 1 ]] || fail "$zip: expected exactly one .x86_64 binary"
			grep -q '^libgodotopus.*\.so$' <<<"$listing" || fail "$zip: missing the opus GDExtension"
			grep -q '^libgodotopenxrvendors.*\.so$' <<<"$listing" || fail "$zip: missing the OpenXR vendors GDExtension"
			# unzip -Z prints the unix mode; the binary must stay executable.
			if [[ "$ZIP_TOOL" == "zip" ]]; then
				unzip -Z "$zip" | grep '\.x86_64$' | grep -q '^-rwx' || fail "$zip: the binary lost its executable bit"
			fi
			;;
	esac
	[[ "$(grep -c '\.pck$' <<<"$listing")" == 1 ]] || fail "$zip: expected exactly one .pck"
	if grep -qE 'openvr|godot_oculus' <<<"$listing"; then
		fail "$zip: contains Godot 3 leftovers"
	fi
}
check_zip "$DIST/Fugitive3D_Client_Flat_Windows_v${VERSION}.zip"      windows
check_zip "$DIST/Fugitive3D_Client_VR_Windows_v${VERSION}.zip"        windows
check_zip "$DIST/Fugitive3D_Client_VR_Oculus_Windows_v${VERSION}.zip" windows
check_zip "$DIST/Fugitive3D_Server_Windows_v${VERSION}.zip"           windows
check_zip "$DIST/Fugitive3D_Client_Flat_Linux_v${VERSION}.zip"        linux
check_zip "$DIST/Fugitive3D_Server_Linux_v${VERSION}.zip"             linux

# Resource paths are plaintext in an unencrypted pck. The client must carry the
# GameAnalytics keys it reads at startup; the server presets exclude client/*.
grep -aq 'res://keys.json' export/client/flat/windows/Fugitive3D_Client_Flat_Windows.pck \
	|| fail "client pck does not contain keys.json"
if grep -aq 'res://client/' export/server/linux/Fugitive3D_Server_Linux.pck; then
	fail "server pck contains client/ resources"
fi

log "checking Android packages"
quest="$DIST/Fugitive3D_Client_VR_Quest_v${VERSION}.apk"
for lib in libgodot_android.so libgodotopenxrvendors.so libopenxr_loader.so; do
	unzip -Z1 "$quest" | grep -q "^lib/arm64-v8a/$lib$" || fail "Quest APK is missing lib/arm64-v8a/$lib"
done
unzip -Z1 "$quest" | grep -q '^lib/arm64-v8a/libgodotopus.*\.so$' || fail "Quest APK is missing the opus GDExtension"
unzip -Z1 "$DIST/Fugitive3D_Client_Flat_Android_GP_v${VERSION}.aab" | grep -q '^base/manifest/AndroidManifest.xml$' \
	|| fail "the AAB has no base module manifest"

# Package name and version checks need the SDK build tools; skip cleanly when
# packaging on a machine without them.
build_tools=""
if [[ -n "${ANDROID_HOME:-}" ]]; then
	build_tools="$(ls -d "$ANDROID_HOME"/build-tools/*/ 2>/dev/null | sort -V | tail -1 || true)"
fi
if [[ -n "$build_tools" && -x "$build_tools/aapt2" ]]; then
	check_apk() {
		local apk=$1 package=$2 badging
		badging="$("$build_tools/aapt2" dump badging "$apk" | head -1)"
		grep -q "package: name='$package'" <<<"$badging" || fail "$apk: expected package $package, got: $badging"
		grep -q "versionName='$VERSION'" <<<"$badging" || fail "$apk: versionName is not $VERSION: $badging"
		if [[ -n "$VERSION_CODE" ]]; then
			grep -q "versionCode='$VERSION_CODE'" <<<"$badging" || fail "$apk: versionCode is not $VERSION_CODE: $badging"
		fi
		"$build_tools/apksigner" verify --print-certs "$apk" | grep -i 'SHA-256' || fail "$apk: signature verification failed"
	}
	check_apk "$DIST/Fugitive3D_Client_Flat_Android_v${VERSION}.apk" com.darkrockstudios.games.fugitive3d
	check_apk "$quest" com.darkrockstudios.games.vr.fugitive3d
else
	echo "::warning::Android build-tools not found; skipping package name and version checks"
fi

log "dist/"
ls -la "$DIST"
