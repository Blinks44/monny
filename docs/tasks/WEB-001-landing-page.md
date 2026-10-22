# WEB-001: Public landing page

- Updated: 2026-10-22
- Stage: awaiting_verification
- Owner: unassigned
- Ownership checked: 2026-10-22; released after implementation
- Owned surfaces: `apps/website/`
- Requirements: user request 2026-10-22 (one-page site like Rebind's, TanStack Start with SEO, moduix components, Monny's style; a visible first-launch note with the `xattr` command); PLAN phase 5
- Code baseline: main at a2c5c3c; website files uncommitted

## Outcome and scope

A light, airy one-page site in `apps/website/` that presents Monny and leads to the download. Structure, 404, Paraglide localization and Cloudflare Worker hosting follow the Rebind website. Sections: hero with a working popover rendition, stats, features, dashboard window, battery charge limit (interactive slider), optional AI limits, principles, install with the first-launch callout and copyable `xattr` command, FAQ (also FAQPage JSON-LD), call to action. All six app languages. Copy describes only shipped behavior; deferred Discharge/sailing/calibration are not mentioned.

## Acceptance

- [x] `pnpm build` (Rsbuild client + server and `tsc --noEmit`) passes.
- [x] Pages render in Light and Dark, at 1440, 1280 and 390 px wide; `/ru` and `/zh` show translated copy; unknown paths return status 404 with the 404 page.
- [x] Copy button puts `xattr -dr com.apple.quarantine /Applications/Monny.app` on the clipboard.
- [ ] User review of the look and copy, in particular the non-English languages.
- [ ] `pnpm preview` in the Workers runtime and the production domain (`monny.moduix.dev` is an assumption carried over from Rebind's `rebind.moduix.dev`).
- [ ] Download button with a real release: shows `Monny <version>` and links to the DMG once a GitHub release exists.

## Implementation and verification

Agent-observed on 2026-10-22, macOS 27.0.1, Chrome headless through puppeteer-core (outside the repository): full-page screenshots of `/` (1440 Light), `/ru` (1440 Dark, 390 Dark), `/zh` (1280 Light), `/missing` (404), popover Battery and Processes tabs, the copy button. Fixed during review: `Intl` has no `watt` unit, the slider hidden input must live inside the thumb, slider/switch widths, dashboard header layout and chart tooltip space. Screenshots stay local.

Design source: no website frames in Monny.sketch; the renditions follow `01 · Popover` (Overview, Battery, Processes, AI limits) and `02 · Window` (`01 · Window · Overview`). Battery tab shows only the native limit control (`16 · Battery · Native limit control`), not the deferred Charge/Discharge tiles.

Review on 2026-10-22 (simplicity, ready libraries first): hand-written SVG ring, bars and Catmull-Rom sparkline replaced with moduix ProgressCircular, ProgressLinear and Chart (TanStack Charts 1.0.0, pinned to the version moduix 3.0 targets; 1.1.0 makes the moduix tooltip transparent). Dropped the random drift of popover readings, the dashboard range switcher and the hand-written chart hover; the chart tooltip comes from the library. AI sample data became plain values; unused messages, tokens and exports removed. Rechecked: build and type check, `/` at 1440 Light, `/ru` at 390 Dark, popover tabs, chart tooltip on hover. The client bundle grew by about 83 kB gzip for the chart library.

Follow-up on 2026-10-22 (user request): the hero menu bar shares the desktop's grid columns (CSS subgrid), so the popover hangs right under Monny's item with system icons to its right; the popover gained the AI tab with all four tools (shared `lib/ai.ts` and `AiToolCard` with the AI section), and the hero lead mentions AI limits in all six languages. Rechecked `/` at 1440 Light, `/ru` at 390 Dark and the AI tab.

## Next handoff

User: look through the site (`pnpm dev` in `apps/website`) and say what to change. Code: after approval, commit; before the first app release run `pnpm preview`, then `pnpm deploy` only when the user asks to publish.
