# Monny: design direction and live source index

Updated 2026-10-17. [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through Sketch MCP.

## Direction

Calm, light macOS 26 utility: a translucent popover and window chrome over the desktop, white rounded cards with soft shadows and hairlines, one brand accent and a dedicated color per metric (CPU violet, memory teal, disk amber, network blue with violet upload, battery green, heat orange/red). Status uses chips and banners: success green, warning amber, danger red, info blue. SF Pro and SF Symbols; native controls (segmented control, toggles, popup buttons, sliders, checkboxes). Light and Dark share geometry, type and spacing.

## Current source: Monny.sketch

Open **Monny.sketch** through Sketch MCP (load `mcp`, then `use`; resolve the open document by name). The file is kept in the designer's iCloud Drive, outside Git. Reviewed 2026-10-17 during workflow setup; IDs change after saving/reopening, so resolve them live.

| Page | Content |
| --- | --- |
| 01 · Popover | Overview, Battery, Processes; Battery charging / on battery / helper required; Overview thermal alert. Light above, Dark below |
| 02 · Window | Overview, CPU, Memory, Disk, Network, Battery, Sensors, Settings; Light/Dark pairs |
| 03 · Flows & System | Onboarding Welcome / Battery helper / Ready, Calibration in progress, menu bar states, right-click menu and notifications, app icon |
| 04 · Foundations | Colors, typography, spacing/radii/elevation, component overview |
| Symbols | `Light/…` and `Dark/…` buttons, toggles, checkboxes, icon buttons, chips, popup button, banners |

Colors are 88 Color Variables named `Light/<Group>/<Name>` and `Dark/<Group>/<Name>` (Text, Surface, Fill, Accent, Metric, Status, State); 12 text styles and 4 layer styles. Code mirrors these variables as one token set; change a token in both places.

Screens are drawn in English only; other languages are checked in the app.

## Readiness

All listed frames are saved and form the target for the first release. Not yet drawn: empty/first-launch dashboard history, unavailable-sensor and Mac-without-battery variants, Settings error states (helper install failed, update check failed). Engineering can start foundations and readings; a design task should add those states before their screens are implemented.

## Rules that apply to every screen

- Use the shared symbols and color variables; no raw hex on screens.
- A metric keeps its color everywhere (card icon, chart, bar, chip).
- Values that cannot be read show as unavailable, never as zero.
- Increase Contrast strengthens text and edges; Reduce Motion removes chart and gauge animation. Keyboard focus, VoiceOver and localized expansion are accepted in the app, not in Sketch.
- Sketch is saved separately from Git. If it is unavailable, ask for the document and continue independent engineering; do not substitute an old PNG. Verification screenshots stay local under [WORKFLOW](WORKFLOW.md#repository-content-and-language).

## Brand

The app icon (page `03`, frame `06 · Brand · App icon`) is a dark graphite tile with three rounded bars in violet, blue and green; the menu bar uses a monochrome template of the bars (16×14 pt) with an optional 7 pt alert dot. Export the icon into an Icon Composer `.icon` asset when the foundations task adds it.

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task note. Record changed behavioral requirements in SPEC and native results in verification.
