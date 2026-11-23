# Security Policy

Monny reads local macOS system statistics and can adjust the built-in macOS battery charge limit (the same setting as **System Settings → Battery**). It runs as an ordinary user-space app without administrator rights or a privileged helper daemon.

## Privacy & Network Model

- System metrics stay on your Mac. There is no account, analytics, or telemetry.
- **Update checks:** Monny checks the public Sparkle `appcast.xml` on GitHub Releases and verifies downloaded updates with an Ed25519 signature (`SUPublicEDKey`).
- **AI subscription quotas (optional, off by default):** When enabled, Monny queries only the providers you turn on using each tool's existing local sign-in on your Mac (JetBrains AI is read strictly from local IDE files). Monny never transmits credentials to any third-party backend.
- Monny shows process names, ports, and resource usage, and never inspects file contents, keystrokes, or network payloads.
- Battery charge limit writes are fail-safe: if the native setting cannot be verified, macOS keeps full control of charging.

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for a security vulnerability. Use **Security → Report a vulnerability** on GitHub ([private advisory form](https://github.com/Blinks44/monny/security/advisories/new)).

Include your Monny version, macOS version, Mac model, and reproduction steps. Expect an initial response within 7 days.

## Supported Versions

Security fixes are shipped on the latest release.
