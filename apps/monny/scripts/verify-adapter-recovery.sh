#!/bin/bash
# Subprocess/checkpoint verification only: no helper registration or physical SMC operation.
set -euo pipefail
app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d -t monny-adapter-process)"
trap 'rm -rf "$work"' EXIT
mkdir "$work/state"
chmod 700 "$work/state"
xcrun swiftc -swift-version 6 -parse-as-library -o "$work/fixture" \
    "$app_root/BatteryHelperShared/SMC.swift" \
    "$app_root/BatteryHelperShared/ChargeCapabilityProbe.swift" \
    "$app_root/BatteryHelperShared/NativeChargeLimit.swift" \
    "$app_root/BatteryHelperShared/AdapterBytePulseReport.swift" \
    "$app_root/BatteryHelperShared/AdapterIsolationCommand.swift" \
    "$app_root/BatteryHelperShared/AdapterVerificationTransaction.swift" \
    "$app_root/BatteryHelperShared/NativeChargeLimitJournal.swift" \
    "$app_root/scripts/fixtures/AdapterRecoveryProcess.swift"
set +e
"$work/fixture" crash "$work/state"
crash_result=$?
set -e
if [[ "$crash_result" != 75 ]]; then
    echo "Expected fixture-only termination was not observed" >&2
    exit 1
fi
"$work/fixture" recover "$work/state"
"$work/fixture" recoverAgain "$work/state"
echo "Separate-process injected adapter recovery passed; no hardware accessed."
