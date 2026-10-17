# Security

Monny reads system statistics and, with an optional privileged helper, changes how the Mac charges its battery. The helper runs with administrator rights, so security reports are especially welcome.

## What Monny does and does not do

- Readings come from your Mac and stay on it. There is no account, analytics or telemetry; the only network request is the update check.
- Monny shows process names and resource use but does not read file contents, keystrokes or network traffic.
- The battery helper is installed only when you ask for it, after the standard macOS administrator prompt. It only accepts charging commands from the signed Monny app and can be removed in Settings → Battery.
- If the helper or a reading is unavailable, Monny leaves charging to macOS.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use **Security → Report a vulnerability** on the repository's GitHub page (private vulnerability reporting). Include the affected version, your macOS version, your Mac model and the steps to reproduce.

You can expect an acknowledgement within a week. This is a volunteer project, so fixes are made as time allows; you will be told what is planned and credited in the release notes unless you prefer otherwise.

## Supported versions

Only the latest release receives fixes.
