#!/bin/bash
# Builds an arm64 Release, signs it with the existing identity under Hardened Runtime and
# packages the branded DMG in build/release/ with its Sparkle appcast. Never creates keys,
# installs or publishes.
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
sign=(codesign --force --options runtime --timestamp=none --sign "$identity")
# Sparkle is the only embedded framework; anything else needs a signing review first.
frameworks="$(ls "$app/Contents/Frameworks")"
[[ "$frameworks" == "Sparkle.framework" ]] && [[ -z "$(find "$app" -name '*.dylib')" ]] \
    || { echo "Review nested code signing: unexpected frameworks or dylibs in the app" >&2; exit 1; }
# Hardened Runtime library validation needs Sparkle signed with the app's identity, inside out
# (https://sparkle-project.org/documentation/sandboxing/#code-signing).
sparkle="$app/Contents/Frameworks/Sparkle.framework"
"${sign[@]}" "$sparkle/Versions/Current/XPCServices/Installer.xpc"
"${sign[@]}" --preserve-metadata=entitlements "$sparkle/Versions/Current/XPCServices/Downloader.xpc"
"${sign[@]}" "$sparkle/Versions/Current/Autoupdate"
"${sign[@]}" "$sparkle/Versions/Current/Updater.app"
"${sign[@]}" "$sparkle"
"${sign[@]}" "$app"
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

# SHA256SUMS.txt is published with the DMG so downloads can be checked with shasum -c.
(cd "$output" && shasum -a 256 "$(basename "$dmg")" | tee SHA256SUMS.txt)

# Sparkle signs the finished DMG with Monny's EdDSA key from the login keychain (account
# "monny", docs/SIGNING.md). Each release uploads its own appcast with only its DMG, and the app
# reads it from the latest GitHub release, so an older local build is never listed.
appcast="$output/appcast.xml"
rm -f "$appcast"
cp "$dmg" "$staging/"
rm -rf "$staging/Monny.app"
"$app_root/build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast" --account monny \
    --download-url-prefix "https://github.com/Blinks44/monny/releases/download/v$version/" \
    --full-release-notes-url "https://github.com/Blinks44/monny/releases/tag/v$version" \
    --link "https://github.com/Blinks44/monny" -o "$appcast" "$staging" > "$output/appcast.log" 2>&1 \
    || { echo "Appcast failed (is the update signing key in the keychain?); see $output/appcast.log" >&2; exit 1; }
echo "Package: $dmg (signed, not notarized)"
echo "Checksums: $output/SHA256SUMS.txt"
echo "Appcast: $appcast"
