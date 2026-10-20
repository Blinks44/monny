# Monny: design direction and live source index

Updated 2026-10-19. [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through Sketch MCP.

## Direction

Calm, light macOS 26 utility: a translucent popover and window chrome over the desktop, white rounded cards with soft shadows and hairlines, one brand accent and a dedicated color per metric (CPU violet, memory teal, disk amber, network blue with violet upload, battery green, heat orange/red). Status uses chips and banners: success green, warning amber, danger red, info blue. SF Pro and SF Symbols; native controls (segmented control, toggles, popup buttons, sliders, checkboxes). Light and Dark share geometry, type and spacing.

## Current source: Monny.sketch

Open **Monny.sketch** through Sketch MCP (load `mcp`, then `use`; resolve the open document by name). The file is kept in the designer's iCloud Drive, outside Git. Reviewed 2026-10-17 during workflow setup; IDs change after saving/reopening, so resolve them live.

| Page | Content |
| --- | --- |
| 01 · Popover | Overview, Battery, Processes; Battery charging / on battery / helper required; Overview thermal alert; Overview and Battery without a battery. Light above, Dark below |
| 02 · Window | Overview, CPU, Memory, Disk, Network, Battery, Sensors, Settings; Overview first launch, Sensors unavailable, Battery without a battery, Settings errors / update available / uninstall helper confirmation; Battery macOS charging guidance (info entry in the Charging card, standalone Light/Dark source frames); Light/Dark pairs |
| 03 · Flows & System | Onboarding Welcome / Battery helper / Ready, plus Welcome / Ready for a Mac without a battery, Calibration in progress, menu bar states, right-click menu and notifications, app icon; branded DMG window and standalone pending-helper-approval and connection-recovery Light/Dark references |
| 04 · Foundations | Colors, typography, spacing/radii/elevation, component overview |
| Symbols | `Light/…` and `Dark/…` buttons, toggles, checkboxes, icon buttons, chips, popup button, banners |

Colors are 94 Color Variables named `Light/<Group>/<Name>` and `Dark/<Group>/<Name>` (Text, Surface, Fill, Accent, Metric, Status, State); 12 text styles and 4 layer styles. Code mirrors these variables as one token set; change a token in both places.

Battery guidance was saved and reviewed live on 2026-10-19 ([APP-005](tasks/APP-005-battery-design-parity.md)); current charging controls stay off until hardware support is implemented.

Screens are drawn in English only; other languages are checked in the app.

The saved DMG frame/background and clearer helper-approval references were reviewed live on 2026-10-19 ([REL-002](tasks/REL-002-branded-dmg.md), [APP-006](tasks/APP-006-helper-approval-clarity.md)). DMG background is a fixed light, text-free installation canvas apart from the Monny brand; Finder owns the actual icons and filenames.

Helper connection recovery card/action references were saved and reviewed live on 2026-10-19 ([BAT-008](tasks/BAT-008-helper-recovery-ui.md)); they supersede bare retry/removal links. The popover stays open through confirmation and system authorization; removal always asks for confirmation.

## Readiness

All listed frames are saved and form the target for the first release. Every state in SPEC has a frame, including empty, unavailable, no-battery, error, update and confirmation states ([DES-001](tasks/DES-001-missing-states.md)). Accessibility and the other five languages are accepted in the app.

## Rules that apply to every screen

- Use the shared symbols and color variables; no raw hex on screens.
- A metric keeps its color everywhere (card icon, chart, bar, chip).
- Values that cannot be read show as unavailable, never as zero.
- Increase Contrast strengthens text and edges; Reduce Motion removes chart and gauge animation. Keyboard focus, VoiceOver and localized expansion are accepted in the app, not in Sketch.
- Sketch is saved separately from Git. If it is unavailable, ask for the document and continue independent engineering; do not substitute an old PNG. Verification screenshots stay local under [WORKFLOW](WORKFLOW.md#repository-content-and-language).

## Brand

The app icon (page `03`, frame `06 · Brand · App icon`) is a graphite tile with three rounded bars, violet, teal and green (CPU, memory, battery), and no baseline. The menu bar uses a monochrome template of the bars (16×14 pt) with an optional 7 pt alert dot. [AppIcon.icon](../apps/monny/monny/AppIcon.icon/) is the only app-icon input: a graphite linear-gradient fill plus one SVG layer per bar, composed by Icon Composer. To revise it, change the geometry in Sketch, update the SVG layers (1024 canvas = 2× the 512 frame), rebuild and inspect `Monny.app/Contents/Resources/AppIcon.icns`. Do not bake a corner mask, shadow or background into the layers. `docs/images/app-icon.png` is the README preview exported from a build.

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task note. Record changed behavioral requirements in SPEC and native results in verification.
