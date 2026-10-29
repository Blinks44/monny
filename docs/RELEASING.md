# Publishing Monny

Maintainer checklist for a GitHub release and the website. Run commands from the repository root. Packaging, commits, GitHub publication and website deployment are separate steps; nothing here runs automatically. Signing and key backups: [SIGNING](SIGNING.md).

## 1. Set the version and build

In Xcode, open target **monny** → General → Identity, or edit `apps/monny/monny.xcodeproj/project.pbxproj`, keeping Debug and Release equal:

- **Version** (`MARKETING_VERSION`): semantic version `MAJOR.MINOR.PATCH`, for example `1.0.1` for fixes and `1.1.0` for new features. The tag is `v<Version>`.
- **Build** (`CURRENT_PROJECT_VERSION`): raised for every app change. Sparkle compares this number, so each published release needs a build larger than all earlier ones.

Never publish different bytes under a version that is already public: raise the build and the version instead. Set the version before packaging any build you install: an installed local package with the same build number as the release (even under an older version) makes Sparkle report it as up to date. Builds before 34 only have the old manual update check and must be replaced by hand once.

## 2. Write the notes and changelog

Add `## <Version>: <date>` to [CHANGELOG](../CHANGELOG.md) and the release notes in `docs/releases/<Version>.md` (see [1.0.0](releases/1.0.0.md)): what changed, how to install, known limits and the tested Mac/macOS. `release.sh` requires this file and embeds its text above `## Install or update` (without the title) in the appcast, so the update window shows it. Commit everything, so the tag points at the exact source of the package.

## 3. Build the package

```sh
apps/monny/scripts/dev.sh test
apps/monny/scripts/release.sh
```

`release.sh` writes `Monny.dmg` (it prints the version and build inside), `SHA256SUMS.txt` and the signed Sparkle `appcast.xml` to `apps/monny/build/release/`. Install that DMG yourself and check it before publishing.

## 4. Tag and create a draft

With the [GitHub CLI](https://cli.github.com) (`brew install gh`, then `gh auth login` once):

```sh
git push origin main
git tag -a v1.0.0 -m "Monny 1.0.0"
git push origin v1.0.0
gh release create v1.0.0 --draft --verify-tag --title "Monny 1.0.0" \
  --notes-file docs/releases/1.0.0.md \
  apps/monny/build/release/Monny.dmg \
  apps/monny/build/release/SHA256SUMS.txt \
  apps/monny/build/release/appcast.xml
gh release view v1.0.0 --web
```

A draft is visible only to the maintainer, and the app ignores drafts and pre-releases. The app reads `releases/latest/download/appcast.xml`, so every stable release carries its own appcast, whose download URL points at `releases/download/v<Version>/Monny.dmg`; keep the tag and DMG filename unchanged. The fixed name also makes `releases/latest/download/Monny.dmg` a permanent link to the newest release, used by the website and README (1.1.0 carries a byte-identical `Monny.dmg` copy beside its original asset).

## 5. Publish and check

```sh
gh release edit v1.0.0 --draft=false --latest
curl -fsSL https://github.com/Blinks44/monny/releases/latest/download/appcast.xml
```

The appcast must show the new build. Download the DMG from the release and run `shasum -a 256 -c SHA256SUMS.txt` next to it. **Check for Updates** in the installed app should say it is up to date. An installed previous version should offer the update.

## 6. Website

Nothing to do for a release: the download buttons use `releases/latest/download/Monny.dmg`, which follows the newest stable release. Deploy the website (`pnpm deploy` in `apps/website`) only for website changes. Details: [website README](../apps/website/README.md).
