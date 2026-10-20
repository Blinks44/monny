# APP-005: Battery layout parity and macOS charging guidance

- Updated: 2026-10-19
- Stage: awaiting_verification (final user visual acceptance)
- Owner: unassigned
- Ownership checked: main at fd8ba18; released; prior BAT-001–003 changes preserved
- Owned surfaces: BatteryPage, charging guidance view, String Catalog, relevant Sketch Battery frames and guidance states, related records
- Requirements: SPEC Battery window, charging setup; DESIGN live source
- Baseline: fd8ba18 plus uncommitted battery foundations/helper work

## Outcome and scope

Bring Battery's card structure, explanatory rows, calibration steps and trip setup closer to the live Sketch source. Keep unsupported controls visibly disabled and omit invented history, scheduled trips and charge sessions. Research interaction with macOS charging settings and provide manual guidance without detecting or changing unknown system settings. The user owns helper installation; this task does not register or remove it.

## Acceptance

- [x] Live Light/Dark Sketch source inspected; relevant additions saved and reviewed.
- [x] Charging rows, slider preview, calibration connectors/footer and trip selectors match the source structure, including localized expansion.
- [x] macOS charging guidance distinguishes monitoring from future active control; six translations and a Battery Settings link.
- [x] Build and native visual verification, documentation and next checks recorded.

## Research and open checks

Apple confirms Optimized Battery Charging can delay charging above 80%; macOS 26.4+ on Apple silicon also offers an 80–100% Charge Limit. A third-party controller can request charging while macOS independently inhibits it. Turning off optimization and setting the system limit to 100% is preparation for predictable future Monny control, not required to run monitoring or the current status-only helper. Actual Monny backend coexistence remains a hardware gate; do not present the settings as detected on/off.

Sources and mechanism decision: [battery research](../research/battery-control.md#macos-charging-settings-2026-10-19). Final native/Sketch checks, separate review DMG, 63 passing tests, intentional differences and remaining checks: [verification](../verification/battery-design-parity.md).

## Next handoff

User reviews the updated Battery layout and guidance in the latest build/release DMG (the superseded DesignReview output was cleaned during BAT-004). Helper installation remains user-owned under BAT-003; monitoring and this UI do not require changing system charging settings. Hardware charge control remains disabled. No Git commit made.
