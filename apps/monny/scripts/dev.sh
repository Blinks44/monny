#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Respect an explicit toolchain or a valid system selection. Fall back locally
# when xcode-select points to Command Line Tools; never change system settings.
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    selected_developer_dir="$(xcode-select -p 2>/dev/null || true)"
    if [[ -x "$selected_developer_dir/usr/bin/xcodebuild" ]]; then
        export DEVELOPER_DIR="$selected_developer_dir"
    elif [[ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]]; then
        export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    else
        echo "Full Xcode is required. Set DEVELOPER_DIR to its Contents/Developer directory." >&2
        exit 1
    fi
fi

command_name="${1:-build}"
if [[ $# -gt 0 ]]; then shift; fi
common_args=(-project monny.xcodeproj -scheme monny -destination 'platform=macOS' -derivedDataPath "$repo_root/build/DerivedData")

case "$command_name" in
    doctor)
        xcodebuild -version
        xcrun swift --version
        xcrun swift package --version
        xcrun --sdk macosx --show-sdk-version
        sw_vers
        exec xcodebuild -list -project monny.xcodeproj "$@"
        ;;
    build|build-for-testing|test)
        exec xcodebuild "$command_name" "${common_args[@]}" -configuration Debug "$@"
        ;;
    release)
        exec xcodebuild build "${common_args[@]}" -configuration Release "$@"
        ;;
    resolve)
        exec xcodebuild -resolvePackageDependencies "${common_args[@]}" "$@"
        ;;
    run)
        xcodebuild build "${common_args[@]}" -configuration Debug "$@"
        exec open "$repo_root/build/DerivedData/Build/Products/Debug/Monny.app"
        ;;
    *)
        echo "Usage: $0 {doctor|build|release|build-for-testing|test|resolve|run} [xcodebuild arguments]" >&2
        exit 2
        ;;
esac
