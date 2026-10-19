#!/bin/bash
# Package with an existing identity; key creation is never part of a release.
set -euo pipefail
exec python3 - "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" <<'PYTHON'
#!/usr/bin/env python3
"""Build with an existing signing identity; never create keys or install a service."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

APP_ROOT = Path(sys.argv[1])
OUTPUT = Path(os.environ.get("MONNY_PACKAGE_DIR", str(APP_ROOT / "build" / "release"))).resolve()
KEYCHAIN = os.environ.get("MONNY_SIGN_KEYCHAIN")
IDENTITY = os.environ.get("MONNY_SIGN_IDENTITY", "Monny Local Signing")
HELPER_ID = "blinks44.monny.battery-helper"


def run(*args, quiet=False):
    result = subprocess.run([str(a) for a in args], stdout=subprocess.PIPE if quiet else None,
                            stderr=subprocess.PIPE if quiet else None)
    if result.returncode:
        # Never echo command arguments: keychain commands contain credentials.
        detail = result.stderr.decode(errors="replace").strip() if quiet and result.stderr else ""
        raise RuntimeError(f"{Path(str(args[0])).name} failed (exit {result.returncode})" + (f": {detail}" if detail else ""))
    return result.stdout


def signing_identity():
    args = ["security", "find-identity", "-p", "codesigning"]
    if KEYCHAIN:
        args.append(KEYCHAIN)
    output = run(*args, quiet=True).decode()
    # Self-signed identities may be excluded by -v; exact fingerprint authentication is
    # performed by codesign/native fixture checks, without adding system trust exceptions.
    found = {fingerprint for fingerprint, name in re.findall(r'\d+\) ([A-Fa-f0-9]{40}) "([^"\n]+)"', output)
             if name == IDENTITY or fingerprint.lower() == IDENTITY.lower()}
    if len(found) != 1:
        raise RuntimeError(
            "Expected exactly one signing identity. Import the existing certificate AND private key "
            "from its .p12 backup into Keychain Access. Preserve the "
            "original signing identity. No new certificate was created.")
    return next(iter(found))


def main():
    os.umask(0o077)
    fingerprint = signing_identity()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    log = OUTPUT / "build.log"
    with log.open("w") as stream:
        result = subprocess.run([str(APP_ROOT / "scripts" / "dev.sh"), "release", "ARCHS=arm64", "ONLY_ACTIVE_ARCH=YES"], stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f"Release build failed; inspect {log}")
    destination = OUTPUT / "Monny.app"
    if destination.exists():
        shutil.rmtree(destination)
    run("ditto", APP_ROOT / "build/DerivedData/Build/Products/Release/Monny.app", destination)
    sign = ["codesign", "--force", "--options", "runtime", "--timestamp=none", "--sign", fingerprint]
    if KEYCHAIN:
        sign.extend(["--keychain", KEYCHAIN])
    # Current release contains one helper and no dynamic packages. Fail rather than silently
    # introducing library-validation exceptions if that bundle contract changes.
    if list(destination.rglob("*.dylib")) or list(destination.rglob("*.framework")):
        raise RuntimeError("Review nested dynamic code signing before packaging this bundle")
    helper = destination / "Contents/Library/HelperTools/MonnyBatteryHelper"
    run(*sign, "--identifier", HELPER_ID, helper, quiet=True)
    run(*sign, destination, quiet=True)
    run("codesign", "--verify", "--strict", "--deep", destination, quiet=True)
    run(APP_ROOT / "scripts" / "verify-helper-signing.sh", destination, KEYCHAIN or "", fingerprint)
    import plistlib
    info = plistlib.loads((destination / "Contents/Info.plist").read_bytes())
    version = str(info["CFBundleShortVersionString"])
    build = str(info["CFBundleVersion"])
    if not all(re.fullmatch(r"[A-Za-z0-9._-]+", item) for item in [version, build]):
        raise RuntimeError("Invalid version/build for package filename")
    dmg = OUTPUT / f"Monny-{version}-{build}.dmg"
    with tempfile.TemporaryDirectory(prefix="monny-dmg-") as staging:
        run("ditto", destination, Path(staging) / "Monny.app")
        (Path(staging) / "Applications").symlink_to("/Applications", target_is_directory=True)
        run("hdiutil", "create", "-ov", "-format", "UDZO", "-volname", "Monny",
            "-srcfolder", staging, dmg, quiet=True)
    run(*sign, dmg, quiet=True)
    run("codesign", "--verify", "--strict", dmg, quiet=True)
    run("hdiutil", "verify", dmg, quiet=True)
    run("shasum", "-a", "256", dmg)
    print(f"Signing certificate: {fingerprint}")
    print("Prepared status-only test DMG. No helper registered; no charging changes.")
    print("This artifact is self-signed and not notarized. Clean-Mac installation remains unverified.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError) as error:
        print(f"Preparation stopped: {error}", file=sys.stderr)
        sys.exit(1)

PYTHON
