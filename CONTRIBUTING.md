# Contributing to Monny

Thanks for your interest. Monny is a small, free macOS app maintained in spare time; clear reports and focused changes help the most.

## Reporting a problem

Open an issue and include:

- your Monny version, macOS version and Mac model with its chip;
- whether the battery helper is installed;
- what you did, what you expected and what happened;
- for a wrong reading, what Activity Monitor or System Information shows for the same value.

For security problems, especially anything involving the battery helper, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Proposing a change

For anything larger than a small fix, open an issue first so the approach can be agreed before you spend time on it. Monny deliberately stays small: local readings, a charge limit, no telemetry and no accounts.

## Building and testing

You need full Xcode with a Swift 6.2+ compiler and a macOS 26+ SDK.

```sh
apps/monny/scripts/dev.sh build
apps/monny/scripts/dev.sh test
```

See the [development guide](docs/DEVELOPMENT.md) for details.

## Pull requests

- Keep one topic per pull request and describe how you checked it. Say plainly what you could not test, for example a Mac model or sensor you do not have.
- Follow the existing style: Swift 6 strict concurrency, SwiftUI with AppKit only where needed, no new dependencies without discussion.
- Changes to the battery helper or charging logic must keep the fail-safe rules in [docs/ENGINEERING.md](docs/ENGINEERING.md): when anything is unknown, macOS keeps control of charging.
- User-facing text goes into the String Catalogs in every supported language. If you cannot translate one, say so in the pull request.
- Add or update tests for behavior you change.

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
