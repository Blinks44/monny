# Monny: design direction and live source index

Updated 2026-10-25 (DES-004). [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through Sketch MCP.

## Direction

Calm, light macOS 26 utility: a translucent popover and window chrome over the desktop, white rounded cards with soft shadows and hairlines, one brand accent and a dedicated color per metric (CPU violet, memory teal, disk amber, network blue with violet upload, battery green, heat orange/red). Status uses chips and banners: success green, warning amber, danger red, info blue. SF Pro and SF Symbols; native controls (segmented control, toggles, popup buttons, sliders, checkboxes). Light and Dark share geometry, type and spacing.

## Current source: Monny.sketch

Open **Monny.sketch** through Sketch MCP (load `mcp`, then `use`; resolve the open document by name). The file is kept in the designer's iCloud Drive, outside Git. Reviewed 2026-10-17 during workflow setup; IDs change after saving/reopening, so resolve them live.

| Page | Content |
| --- | --- |
| 01 · Popover | Overview, Battery, Battery on battery, Processes grouped by app, Overview and Battery without a battery, AI limits `11`–`15`; DES-004 proposals `16`–`23`. Light above, Dark below |
| 02 · Window | Overview, CPU, Memory, Disk, Network, Battery (native limit), Sensors; Overview first launch, Sensors unavailable, Battery without a battery; `15` macOS charging guidance, `16` native limit control, `17 · Settings · Native`, `18 · Battery · Power card`, AI `19`–`22`; Light/Dark pairs |
| 03 · Flows & System | Onboarding Welcome / Charge limit (`12`) / Ready (`13`, with AI limits), Welcome / Ready without a battery, menu bar states, right-click menu and notifications, app icon, branded DMG window |
| 04 · Foundations | Colors, typography, spacing/radii/elevation, component overview |
| Symbols | `Light/…` and `Dark/…` buttons, toggles, checkboxes, icon buttons, chips, popup button, banners |

Colors are 94 Color Variables named `Light/<Group>/<Name>` and `Dark/<Group>/<Name>` (Text, Surface, Fill, Accent, Metric, Status, State); 12 text styles and 4 layer styles. Code mirrors these variables as one token set; change a token in both places.

Screens are drawn in English only; other languages are checked in the app.

The saved DMG frame/background was reviewed live on 2026-10-19 ([REL-002](tasks/REL-002-branded-dmg.md)). DMG background is a fixed light, text-free installation canvas apart from the Monny brand; Finder owns the actual icons and filenames.

## Battery: what the app implements — 2026-10-21

The app implements the native charge limit only ([APP-007](tasks/APP-007-native-simplification-design-parity.md)): the popover Battery hero (72 pt gauge, dotted limit marker), the standalone `16 · Battery · Native limit control` reference (80/85/90/95/100 slider where 100% means no limit, then an Optimized Battery Charging switch; 2026-10-22, [APP-014](tasks/APP-014-limit-slider-optimized-charging.md)) and the macOS charging guidance popover. Sketch shows the app as built (user decision 2026-10-24): helper, Charge/Discharge, sailing, heat protection, calibration and trip frames were removed on 2026-10-25 and are redrawn when that work is taken up ([DES-004](tasks/DES-004-power-search-quit-ai-tools.md)). Window content begins at x=248 with a 776 pt column in a 1040 pt window; the toolbar starts at y=20.

## Readiness

The onboarding Ready step gained the automatic updates toggle on 2026-10-21 (Sparkle). Native onboarding, grouped processes, menu bar readings, the sustained-load notification, native Settings and the Power card were drawn on 2026-10-21 ([DES-002](tasks/DES-002-native-onboarding-next-features.md)). Settings is frame `17` (revised 2026-10-22: stacked menu bar checkboxes, About in the right column with the automatic updates row).

AI limits: `01 · Popover` frames `11`–`13 · Popover · AI limits` and `02 · Window` frames `19 · Window · AI limits` and `20 · Window · Settings · AI limits`, `03 · Flows & System` frame `13 · Onboarding · Ready · AI limits`, Light/Dark ([DES-003](tasks/DES-003-ai-usage-limits.md), 2026-10-22). Implemented for Claude Code, Codex, Cursor and Grok ([APP-015](tasks/APP-015-ai-usage-limits.md)). Added 2026-10-22: `14 · Popover · AI limits · Model limits`, `15 · Popover · AI limits · Cursor & Grok` (Grok slate with “G”), `02 · Window` › `21 · Window · AI limits · Four tools` (2×2 tiles, four reset rows) and `22 · Window · Settings · AI tools` (a checkbox per found tool); Light/Dark, saved. The taller frames put Dark at y 1100. Service marks are the `Light/…` and `Dark/AI Logo/<tool>` symbols (brand tiles: Claude coral, Codex and Grok white, Cursor black), used in all AI frames.

All listed frames are saved. Every current SPEC state has a frame, including empty, unavailable and no-battery states ([DES-001](tasks/DES-001-missing-states.md)); update checks use Sparkle's own windows. Accessibility and the other five languages are checked in the app.

The right-click specimen shows Check for Updates instead of About Monny (requested 2026-10-23, drawn 2026-10-25).

Next release design, accepted by the user 2026-10-25: popover `16`–`23` (power draw on Overview and Battery, process search, Quit/Force Quit menu and confirmation, more AI tools); see [DES-004](tasks/DES-004-power-search-quit-ai-tools.md).

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

Reviewed and saved 2026-10-23: **Monny.sketch → 05 · Website** owns desktop/mobile landing/404, menu, installation/language states and self-contained `Website · Implementation notes`. Follow its moduix Calm/CSS Modules tokens, system typography, dark-only website palette and current native-only battery scope. The website/export handoff in both **Monny.sketch** and **Rebind.sketch** is ready: named fixed `Export · Web` Frames have verified 2x PNG/WebP presets, transparent margins and clean window bounds. Monny popover retains the full shadow and an opaque silhouette backing to prevent text bleed; Rebind clips Canvas glow with matching smooth 26 px corners on all five website device exports. The latest review aligns language-menu/Drawer sizing and source 404 surfaces; handoff notes were updated and both documents saved. Existing website crops are composition references, not asset-export sources. Implementation/verification and remaining interaction/accessibility/translation acceptance are in [WEB-001](tasks/WEB-001-landing-page.md). Pending-release/noindex behavior remains intentional.

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task note. Record changed behavioral requirements in SPEC and native results in verification.
