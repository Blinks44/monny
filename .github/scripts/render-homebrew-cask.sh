#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <version> <dmg-sha256>" >&2
  exit 1
fi

version="$1"
sha256="$2"

if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "error: invalid version: $version" >&2
  exit 1
fi

if ! [[ "$sha256" =~ ^[0-9a-fA-F]{64}$ ]]; then
  echo "error: invalid sha256: $sha256" >&2
  exit 1
fi

sha256=$(printf '%s' "$sha256" | tr '[:upper:]' '[:lower:]')

cat <<CASK
cask "monny" do
  version "${version}"
  sha256 "${sha256}"

  url "https://github.com/Blinks44/monny/releases/download/v#{version}/Monny.dmg"
  name "Monny"
  desc "Menu bar system monitor, battery charge limit, and AI quota tracker"
  homepage "https://monny.moduix.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Monny.app"

  zap trash: [
    "~/Library/Application Support/Monny",
    "~/Library/Caches/blinks44.monny",
    "~/Library/HTTPStorages/blinks44.monny",
    "~/Library/Preferences/blinks44.monny.plist",
    "~/Library/Saved Application State/blinks44.monny.savedState",
  ]

  caveats <<~EOS
    Monny is signed without Apple notarization.
    If macOS blocks the first launch, open System Settings -> Privacy & Security
    and click "Open Anyway", or run:
      xattr -dr com.apple.quarantine /Applications/Monny.app
  EOS
end
CASK
