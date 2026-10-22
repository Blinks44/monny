# Monny: design direction and live source index

Updated 2026-10-21 (DES-002). [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through Sketch MCP.

## Direction

Calm, light macOS 26 utility: a translucent popover and window chrome over the desktop, white rounded cards with soft shadows and hairlines, one brand accent and a dedicated color per metric (CPU violet, memory teal, disk amber, network blue with violet upload, battery green, heat orange/red). Status uses chips and banners: success green, warning amber, danger red, info blue. SF Pro and SF Symbols; native controls (segmented control, toggles, popup buttons, sliders, checkboxes). Light and Dark share geometry, type and spacing.

## Current source: Monny.sketch

Open **Monny.sketch** through Sketch MCP (load `mcp`, then `use`; resolve the open document by name). The file is kept in the designer's iCloud Drive, outside Git. Reviewed 2026-10-17 during workflow setup; IDs change after saving/reopening, so resolve them live.

| Page | Content |
| --- | --- |
| 01 · Popover | Overview, Battery, Processes; Battery charging / on battery / helper required; Overview thermal alert; Overview and Battery without a battery; Processes grouped by app. Light above, Dark below |
| 02 · Window | Overview, CPU, Memory, Disk, Network, Battery, Sensors, Settings; Overview first launch, Sensors unavailable, Battery without a battery, Settings errors / update available / uninstall helper confirmation; Battery macOS charging guidance (info entry in the Charging card, standalone Light/Dark source frames); `17 · Settings · Native` (current Settings for main); `18 · Battery · Power card`; Light/Dark pairs |
| 03 · Flows & System | Onboarding Welcome / Charge limit (`12`, native step for main) / Ready, the older Battery helper step, plus Welcome / Ready for a Mac without a battery, Calibration in progress, menu bar states, right-click menu and notifications, app icon; branded DMG window and standalone pending-helper-approval and connection-recovery Light/Dark references |
| 04 · Foundations | Colors, typography, spacing/radii/elevation, component overview |
| Symbols | `Light/…` and `Dark/…` buttons, toggles, checkboxes, icon buttons, chips, popup button, banners |

Colors are 94 Color Variables named `Light/<Group>/<Name>` and `Dark/<Group>/<Name>` (Text, Surface, Fill, Accent, Metric, Status, State); 12 text styles and 4 layer styles. Code mirrors these variables as one token set; change a token in both places.

Screens are drawn in English only; other languages are checked in the app.

The saved DMG frame/background was reviewed live on 2026-10-19 ([REL-002](tasks/REL-002-branded-dmg.md)). DMG background is a fixed light, text-free installation canvas apart from the Monny brand; Finder owns the actual icons and filenames.

## Battery: what the app implements — 2026-10-21

The app implements the native charge limit only ([APP-007](tasks/APP-007-native-simplification-design-parity.md)): the popover Battery hero (72 pt gauge, dotted limit marker), the standalone `16 · Battery · Native limit control` reference (80/85/90/95/100 slider where 100% means no limit, then an Optimized Battery Charging switch; 2026-10-22, [APP-014](tasks/APP-014-limit-slider-optimized-charging.md)) and the macOS charging guidance popover. Helper install/approval/recovery frames, Charge/Discharge mode tiles, sailing, heat protection, calibration and trips stay in Sketch for later work; the app does not show them, not even disabled (production review 2026-10-21). Window content begins at x=248 with a 776 pt column in a 1040 pt window; the toolbar starts at y=20.

## Readiness

The onboarding Ready step gained the automatic updates toggle on 2026-10-21 (Sparkle). Native onboarding, grouped processes, menu bar readings, the sustained-load notification, native Settings and the Power card were drawn on 2026-10-21 ([DES-002](tasks/DES-002-native-onboarding-next-features.md)). Frames `08 · Settings` and `06 · Battery` keep the helper-era layout for later work; implement Settings from frame `17` (revised 2026-10-22: stacked menu bar checkboxes, About in the right column with the automatic updates row).

AI limits: `01 · Popover` frames `11`–`13 · Popover · AI limits` and `02 · Window` frames `19 · Window · AI limits` and `20 · Window · Settings · AI limits`, `03 · Flows & System` frame `13 · Onboarding · Ready · AI limits`, Light/Dark ([DES-003](tasks/DES-003-ai-usage-limits.md), 2026-10-22). Implemented for Claude Code, Codex, Cursor and Grok ([APP-015](tasks/APP-015-ai-usage-limits.md)). Added 2026-10-22: `14 · Popover · AI limits · Model limits`, `15 · Popover · AI limits · Cursor & Grok` (Grok slate with “G”), `02 · Window` › `21 · Window · AI limits · Four tools` (2×2 tiles, four reset rows) and `22 · Window · Settings · AI tools` (a checkbox per found tool); Light/Dark, saved. The taller frames put Dark at y 1100. Service marks are the `Light/…` and `Dark/AI Logo/<tool>` symbols (brand tiles: Claude coral, Codex and Grok white, Cursor black), used in all AI frames.

All listed frames are saved, including the two-mode and 80–100% charging updates above. Every state in SPEC has a frame, including empty, unavailable, no-battery, error, update and confirmation states ([DES-001](tasks/DES-001-missing-states.md)). Accessibility and the other five languages are checked in the app.

## Rules that apply to every screen

- Use the shared symbols and color variables; no raw hex on screens.
- A metric keeps its color everywhere (card icon, chart, bar, chip).
- Values that cannot be read show as unavailable, never as zero.
- Tabs of a segmented control size to their titles plus an equal share of the free width, like a native segmented control, so long translations fit (user report 2026-10-22: Russian “Аккумулятор” overflowed four equal tabs). Frames keep the English equal-width drawing.
- Clicks never fade a control: switches, segments, links, sidebar items and clickable cards keep their look; push and popup buttons darken with `State/Pressed`, like native push buttons (user decision 2026-10-22).
- Increase Contrast strengthens text and edges; Reduce Motion removes chart and gauge animation. Keyboard focus, VoiceOver and localized expansion are accepted in the app, not in Sketch.
- Sketch is saved separately from Git. If it is unavailable, ask for the document and continue independent engineering; do not substitute an old PNG. Verification screenshots stay local under [WORKFLOW](WORKFLOW.md#repository-content-and-language).

## Brand

The app icon (page `03`, frame `06 · Brand · App icon`) is a graphite tile with three rounded bars, violet, teal and green (CPU, memory, battery), and no baseline. The menu bar uses a monochrome template of the bars (16×14 pt) with an optional 7 pt alert dot. [AppIcon.icon](../apps/monny/monny/AppIcon.icon/) is the only app-icon input: a graphite linear-gradient fill plus one SVG layer per bar, composed by Icon Composer. To revise it, change the geometry in Sketch, update the SVG layers (1024 canvas = 2× the 512 frame), rebuild and inspect `Monny.app/Contents/Resources/AppIcon.icns`. Do not bake a corner mask, shadow or background into the layers. `docs/images/app-icon.png` is the README preview exported from a build.

## Website

Reviewed read-only 2026-10-22: **Monny.sketch → 05 · Website** owns the second-version landing and 404 in desktop/mobile sizes, the mobile menu, install-notice state and `Website · Implementation notes`. Follow those notes for moduix Calm/CSS Modules, dark-only semantic tokens, system typography, app-image exports and the first-launch notice. This website direction is separate from the native app's Light/Dark contract. The initialization is ready; full layout transfer is iteration two ([WEB-001](tasks/WEB-001-landing-page.md)). Sketch was not edited in the initialization turn.

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task note. Record changed behavioral requirements in SPEC and native results in verification.
