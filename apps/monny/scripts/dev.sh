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
# Executable files stay outside protected Desktop/Documents checkouts.
cache_root="$HOME/Library/Caches/Monny"
derived_data="${MONNY_DERIVED_DATA:-$cache_root/DerivedData}"
temporary_test_data=""

cleanup_test_build() {
    if [[ -n "$temporary_test_data" ]]; then
        rm -rf -- "$temporary_test_data"
    fi
}

# An explicit path belongs to the caller and is never automatically deleted.
if [[ "$command_name" == test && -z "${MONNY_DERIVED_DATA:-}" ]]; then
    mkdir -p "$cache_root/TestRuns"
    temporary_test_data="$(mktemp -d "$cache_root/TestRuns/run.XXXXXX")"
    derived_data="$temporary_test_data"
    # The owner PID lets clean tell a running test from one left by a force-killed script.
    echo "$$" > "$temporary_test_data/owner.pid"
    trap cleanup_test_build EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
fi
common_args=(-project monny.xcodeproj -scheme monny -destination 'platform=macOS' -derivedDataPath "$derived_data")

case "$command_name" in
    doctor)
        xcodebuild -version
        xcrun swift --version
        xcrun swift package --version
        xcrun --sdk macosx --show-sdk-version
        sw_vers
        exec xcodebuild -list -project monny.xcodeproj "$@"
        ;;
    build|build-for-testing)
        exec xcodebuild "$command_name" "${common_args[@]}" -configuration Debug "$@"
        ;;
    test)
        status=0
        xcodebuild test "${common_args[@]}" -configuration Debug "$@" || status=$?
        # Keep one small summary; the full default test build/report is disposable.
        result_bundle=""
        previous_argument=""
        for argument in "$@"; do
            if [[ "$previous_argument" == -resultBundlePath ]]; then result_bundle="$argument"; fi
            previous_argument="$argument"
        done
        if [[ -z "$result_bundle" ]]; then
            for candidate in "$derived_data/Logs/Test/"*.xcresult; do
                if [[ -d "$candidate" ]]; then result_bundle="$candidate"; fi
            done
        fi
        if [[ -n "$result_bundle" ]] && xcrun xcresulttool get test-results summary \
            --path "$result_bundle" --format json > "$derived_data/test-summary.json" 2>/dev/null; then
            mkdir -p "$cache_root"
            mv -f "$derived_data/test-summary.json" "$cache_root/LastTestSummary.json"
            echo "Test summary: $cache_root/LastTestSummary.json"
        fi
        exit "$status"
        ;;
    clean)
        # Only this project's fixed default build cache can be removed here.
        # Never delete a caller-supplied directory or a running app/build's files.
        if [[ -n "${MONNY_DERIVED_DATA:-}" ]]; then
            echo "Unset MONNY_DERIVED_DATA to clean the default build cache." >&2
            exit 1
        fi
        # Missing products can make lsof exit nonzero even when another file has users.
        active_users="$(/usr/sbin/lsof -t "$derived_data/Build/Products/Debug/Monny.app/Contents/MacOS/Monny" \
            "$derived_data/Build/Products/Release/Monny.app/Contents/MacOS/Monny" \
            "$derived_data/Build/Intermediates.noindex/XCBuildData/build.db" 2>/dev/null || true)"
        if [[ -n "$active_users" ]]; then
            echo "Stop builds and quit the app running from the cache before cleaning." >&2
            exit 1
        fi
        rm -rf -- "$derived_data"
        # Runs left by a force-killed test or release; a run whose script is still alive is kept.
        for run in "$cache_root/TestRuns/run."* "$cache_root/ReleaseRuns/run."*; do
            [[ -d "$run" ]] || continue
            owner="$(cat "$run/owner.pid" 2>/dev/null || true)"
            if [[ -n "$owner" ]] && kill -0 "$owner" 2>/dev/null; then continue; fi
            rm -rf -- "$run"
        done
        echo "Build cache cleared. Packaged releases were kept."
        ;;
    release)
        exec xcodebuild build "${common_args[@]}" -configuration Release "$@"
        ;;
    resolve)
        exec xcodebuild -resolvePackageDependencies "${common_args[@]}" "$@"
        ;;
    run)
        xcodebuild build "${common_args[@]}" -configuration Debug "$@"
        exec open "$derived_data/Build/Products/Debug/Monny.app"
        ;;
    *)
        echo "Usage: $0 {doctor|build|release|build-for-testing|test|resolve|run|clean} [xcodebuild arguments]" >&2
        exit 2
        ;;
esac
