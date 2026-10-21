#!/bin/bash
# Builds an arm64 Release, signs it with the existing identity under Hardened Runtime and
# packages the branded DMG in build/release/. Never creates keys, installs or publishes.
set -euo pipefail

app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="$app_root/build/release"
# The pinned Apple Development certificate (docs/SIGNING.md); a missing key stops packaging.
identity="${MONNY_SIGN_IDENTITY:-69D383553450694A1E9D78650B3FC6E69446BD4F}"

command -v create-dmg >/dev/null || { echo "Install create-dmg: brew install create-dmg" >&2; exit 1; }
security find-identity -p codesigning | grep -q "$identity" \
    || { echo "Signing identity $identity is not in the keychain (see docs/SIGNING.md)." >&2; exit 1; }

umask 022
mkdir -p "$output"
"$app_root/scripts/dev.sh" release -quiet CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES > "$output/build.log" 2>&1 \
    || { echo "Release build failed; see $output/build.log" >&2; exit 1; }

app="$output/Monny.app"
rm -rf "$app"
ditto "$app_root/build/DerivedData/Build/Products/Release/Monny.app" "$app"
# DerivedData can keep owner-only modes from older builds; installed apps must be world-readable.
chmod -R u+rwX,go+rX,go-w "$app"
codesign --force --options runtime --timestamp=none --sign "$identity" "$app"
codesign --verify --strict --deep "$app"

info="$app/Contents/Info.plist"
version="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$info")"
build="$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$info")"
dmg="$output/Monny-$version-$build.dmg"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
ditto "$app" "$staging/Monny.app"
create-dmg --overwrite --volname Monny \
    --volicon "$app/Contents/Resources/AppIcon.icns" \
    --background "$app_root/scripts/dmg/background.tiff" \
    --window-size 660 420 --icon-size 128 --text-size 13 \
    --icon Monny.app 170 210 --hide-extension Monny.app \
    --app-drop-link 490 210 --no-internet-enable "$dmg" "$staging" > "$output/create-dmg.log" 2>&1 \
    || { echo "create-dmg failed; see $output/create-dmg.log" >&2; exit 1; }
codesign --force --timestamp=none --sign "$identity" "$dmg"
codesign --verify --strict "$dmg"
hdiutil verify -quiet "$dmg"

shasum -a 256 "$dmg"
echo "Package: $dmg (signed, not notarized)"
