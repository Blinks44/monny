#!/bin/bash
# Verify signed fixtures without installing or running the privileged helper.
set -euo pipefail
app_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# != 3 ]]; then
    echo "Usage: $0 Monny.app signing.keychain-db identity" >&2
    exit 2
fi
artifact="$1"
signing_keychain="$2"
signing_identity="$3"
work="$(mktemp -d -t monny-signing-check)"
trap 'rm -rf "$work"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cat > "$work/main.swift" <<'SWIFT'
import Foundation
import Security

func check(_ condition: Bool, _ message: String) {
    guard condition else {
        FileHandle.standardError.write(Data("Signing check failed: \(message)\n".utf8))
        exit(1)
    }
}
let urls = CommandLine.arguments.dropFirst().map { URL(fileURLWithPath: $0) }
guard urls.count == 5 else { exit(2) }
guard let own = HelperSigning.currentIdentity(for: .app) else {
    check(false, "running signed verifier identity")
    exit(1)
}
check(HelperSigning.currentIdentity(for: .helper) == nil, "running wrong identifier rejected")
check(HelperSigning.identity(at: urls[0], peer: .app) == own, "app matches running signer")
check(HelperSigning.identity(at: urls[1], peer: .helper) == own, "helper matches running signer")
check(HelperSigning.matches(at: urls[1], peer: .helper, identity: own), "positive native requirement")
check(HelperSigning.matches(at: urls[1], peer: .app, identity: own) == false, "wrong peer identifier rejected")
check(HelperSigning.matches(at: urls[1], peer: .helper,
                            identity: .certificate(String(repeating: "0", count: 40))) == false,
      "different certificate rejected")
for fixture in urls[2...] {
    check(HelperSigning.identity(at: fixture, peer: .helper) == nil, "\(fixture.lastPathComponent) identity rejected")
    check(HelperSigning.matches(at: fixture, peer: .helper, identity: own) == false, "\(fixture.lastPathComponent) requirement rejected")
}
print("Signed artifact checks passed: runtime identity, app/helper signer, wrong ID/pin, ad-hoc, debugger, tampering.")
SWIFT
xcrun swiftc -swift-version 6 -o "$work/check" \
    "$app_root/BatteryHelperShared/HelperContract.swift" \
    "$app_root/BatteryHelperShared/NativeChargeLimit.swift" \
    "$app_root/BatteryHelperShared/NativeLimitVerification.swift" \
    "$app_root/BatteryHelperShared/SMC.swift" \
    "$app_root/BatteryHelperShared/ChargeCapabilityProbe.swift" \
    "$app_root/BatteryHelperShared/AdapterCapabilityProbe.swift" \
    "$app_root/BatteryHelperShared/AdapterVerificationReport.swift" \
    "$app_root/BatteryHelperShared/AdapterBytePulseReport.swift" \
    "$app_root/BatteryHelperShared/AdapterByteObservationReport.swift" \
    "$app_root/BatteryHelperShared/AdapterStartupRecovery.swift" \
    "$app_root/BatteryHelperShared/HelperLifecycleDiagnostics.swift" \
    "$app_root/BatteryHelperShared/AdapterLifecyclePreparation.swift" \
    "$app_root/BatteryHelperShared/AdapterVerificationTransaction.swift" \
    "$app_root/BatteryHelperShared/AdapterIsolationCommand.swift" \
    "$app_root/BatteryHelperShared/NativeChargeLimitJournal.swift" \
    "$app_root/BatteryHelperShared/HelperSigning.swift" "$work/main.swift"
sign=(codesign --force --options runtime --timestamp=none --sign "$signing_identity")
if [[ -n "$signing_keychain" ]]; then sign+=(--keychain "$signing_keychain"); fi
"${sign[@]}" --identifier blinks44.monny "$work/check" >/dev/null 2>&1
helper="$artifact/Contents/Library/HelperTools/MonnyBatteryHelper"
cp "$helper" "$work/adhoc"
codesign --force --sign - "$work/adhoc" >/dev/null 2>&1
cp "$helper" "$work/debuggable"
cat > "$work/debug.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.get-task-allow</key><true/></dict></plist>
PLIST
"${sign[@]}" --identifier blinks44.monny.battery-helper --entitlements "$work/debug.plist" "$work/debuggable" >/dev/null 2>&1
cp "$helper" "$work/tampered"
# Alter a signed __TEXT page while leaving the Mach-O/signature structures intact; never execute it.
python3 - "$work/tampered" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
data = bytearray(path.read_bytes())
data[16384] ^= 1
path.write_bytes(data)
PY
"$work/check" "$artifact" "$helper" "$work/adhoc" "$work/debuggable" "$work/tampered"
