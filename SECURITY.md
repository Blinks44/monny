# Security

Monny reads system statistics and can change the macOS battery charge limit, the same setting as System Settings › Battery. It runs as an ordinary app without administrator rights or a background helper.

## What Monny does and does not do

- Readings come from your Mac and stay on it. There is no account, analytics or telemetry. Network requests: the update check (GitHub), and, only if you turn on AI limits, the limit checks with Anthropic, OpenAI, Cursor and xAI using each tool's own sign-in. Monny never stores or sends those tokens anywhere else.
- Monny shows process names and resource use but does not read file contents, keystrokes or network traffic.
- The charge limit changes only when you change it. macOS enforces it; if the setting cannot be read, Monny does not write it.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use **Security → Report a vulnerability** on the repository's GitHub page (private vulnerability reporting). Include the affected version, your macOS version, your Mac model and the steps to reproduce.

You can expect an acknowledgement within a week. This is a volunteer project, so fixes are made as time allows; you will be told what is planned and credited in the release notes unless you prefer otherwise.

## Supported versions

Only the latest release receives fixes.
