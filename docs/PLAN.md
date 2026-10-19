# Monny: roadmap

Updated 2026-10-19. Read [STATE](STATE.md) first for current facts and the task table; [WORKFLOW](WORKFLOW.md) defines how to work; requirements are in [SPEC](SPEC.md). Nothing here is declared complete by a passing build alone.

## Where the product stands

The app shell, live monitoring, history, dashboard pages and Settings are implemented. The earlier design polish is accepted; Battery parity and charging guidance have a final user review open ([APP-005](tasks/APP-005-battery-design-parity.md)); charts, sensor comparisons and notification delivery still have open verification in [STATE](STATE.md). Phase 4 includes the read-only Battery dashboard, tested policy and bundled status-only helper. A self-signed test DMG is prepared; local daemon approval and clean-Mac distribution acceptance are next ([BAT-003](tasks/BAT-003-self-signed-helper.md)), followed by command lease/restoration ([BAT-002](tasks/BAT-002-helper-connection.md)). Hardware charge control is not implemented. Onboarding and release checks remain; launch at login and the manual update check already have implementations. The website follows the app.

## Phases

1. **Foundations** ([APP-001](tasks/APP-001-foundations.md)): menu bar status item and popover shell, dashboard window with sidebar, design tokens from the Sketch color variables, String Catalogs for six languages, logging. Exit: the shell matches the Sketch structure in Light/Dark and builds/tests pass.
2. **Readings** ([CORE-001](tasks/CORE-001-readings-research.md), then [CORE-002](tasks/CORE-002-temperatures-fans.md) for temperatures and fans): research and implement one shared sampler for CPU (total, P/E, per core), memory and pressure, disk space and I/O, network rates, battery/power source, thermal state, temperatures and fans, top processes. Exit: each metric has a capability label and a comparison with Activity Monitor/System Information on a named Mac.
3. **Popover and dashboard screens** on real readings, including history storage for 1m–7d ranges, Settings and notifications.
4. **Battery control** ([BAT-001](tasks/BAT-001-battery-foundations.md), foundations implemented): SMAppService daemon + XPC, connect the policy to verified hardware capabilities, override/trips, calibration and fail-safe behavior. Exit: verified on a named MacBook across sleep, restart, quit and uninstall.
5. **Onboarding, Launch at login, update check, accessibility and localization pass.**
6. **Release preparation** and then the website in `apps/website/`.

## Release gates

- [ ] Every SPEC section implemented or explicitly limited; capability labels recorded per metric.
- [ ] Battery fail-safe verified on hardware: quit, crash, uninstall, sleep/wake and restart all leave charging to macOS when control is off.
- [ ] Idle cost measured for popover open, dashboard open and background.
- [ ] Accessibility: keyboard navigation, VoiceOver, Increase Contrast, Reduce Motion; all six languages at minimum window width.
- [ ] macOS 26 execution checked, not only the newest macOS.
- [ ] Distribution: verify the selected signing route on a clean Mac (self-signed distribution is unproven); signed DMG on GitHub Releases with SHA-256, helper signing requirement matches the app, update check points at the public repository.
