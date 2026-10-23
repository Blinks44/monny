# WEB-001: Public landing page

- Updated: 2026-10-23
- Stage: awaiting_verification (iteration two implemented; final visual/device/release acceptance open)
- Owner: Codex website implementation
- Ownership: Codex website implementation; shared-file editing complete. Baseline main `a63407b`, website/docs changes remain uncommitted. Sketch inspected/exported read-only; no save.
- Owned surfaces: `apps/website/`, website sections in shared docs; Sketch inspected read-only
- Requirements: [SPEC §10](../SPEC.md#10-public-website), user decisions 2026-10-22; PLAN phase 5
- Code baseline: reviewed foundation committed at main `39b3408`; present in cleanup baseline `713defe`

## Current outcome

Iteration two replaces the minimal shells with the saved website design: desktop/narrow landing and 404, shared navigation/mobile Drawer, monitoring cards, native battery demo, AI limits, dashboard gallery, privacy cards, installation tabs and copy feedback, FAQ, CTA and footer. Direct moduix components, CSS Modules, Lucide, the existing TanStack Start/React 19 Worker and Paraglide structure are preserved. All new text and accessible names are translated into EN/RU/DE/FR/ES/zh-Hans.

No public DMG is recorded in the repository. Download actions link to GitHub Releases with a visible pending-release note; `site.downloadUrl` is deliberately unset. `noindex` remains until release/content acceptance. No deployment, DNS change, app change, build-number increment or DMG build is part of this website-only task.

## Acceptance

- [x] React 19/TanStack Start Worker builds with CSS Modules and the requested source structure.
- [x] moduix styles, dark semantic/metric tokens from Sketch, system typography and Lucide imports work. The updated language-menu contract is implemented with real localized links and checked state.
- [x] Paraglide generates type-safe messages for EN/RU/DE/FR/ES/zh-Hans; URL rewrites and request-scoped middleware work.
- [x] Localized server HTML/head, canonical/hreflang, Open Graph/Twitter, SoftwareApplication JSON-LD, robots and sitemap exist; unknown paths return HTTP 404 without a home canonical.
- [x] Oxlint, Oxfmt, TypeScript and ten focused foundation tests pass.
- [x] Production preview runs in workerd; Wrangler packaging succeeds with `--dry-run`.
- [x] All website sections and 404 implemented from the live source; desktop and narrow-layout review performed.
- [ ] Exact 390 px/physical-phone comparison and final active-window tab-indicator check (see review limits below).
- [ ] Review final translations, keyboard/assistive technology and responsive behavior.
- [ ] Real release download and first-launch installation flow (remove the notice when notarized).
- [ ] First authorized production deployment; verify DNS, HTTPS, redirects and indexing on `monny.moduix.dev`.

## Design source

Read-only inspection on 2026-10-22: `Monny.sketch → 05 · Website`, desktop/mobile landing and 404, mobile menu, install-alert state and `Website · Implementation notes`. Dark only, moduix Calm with semantic overrides and system typography. Exact source and notes remain in Sketch; [DESIGN](../DESIGN.md#website) is the short locator. No design exports were committed.

## Implementation and verification

Agent-observed 2026-10-22 on macOS 27.0.1 / Node 24.22.0 / pnpm 12.14.0. Commands from `apps/website`: frozen installation and standard Paraglide `prepare`, `pnpm check` (Oxfmt, Oxlint, `tsc --noEmit`, Vitest: 10 tests), `pnpm build`, `pnpm preview --port 4173 --strictPort`, `pnpm deploy:dry-run`. The latter packages locally without uploading or changing domains.

HTTP verification against the production Worker preview: `/`, `/ru/`, `/de/`, `/fr/`, `/es/`, `/zh-Hans/` return 200 with matching HTML `lang`, localized title, one canonical and seven alternate links. `/missing/`, `/ru/missing/` and `/xx/` return 404 with matching error copy and no canonical. Robots, sitemap and app icon return 200 with the expected media types. Unit tests also verify simultaneous SSR requests retain their own locales. Safari verification: styled dark shell, language selector RU → DE, localized 404 and return-home interaction. The navigation review caught a stale 404 title on return home; moving home metadata to the index route fixed its ownership. Desktop screenshots stay local.

Two upstream warnings remain: moduix 3.0.1 includes `@theme` metadata in its shared stylesheet, which Lightning CSS does not recognize; Vite reports a CSS sourcemap warning. No dependency patch, Tailwind addition or warning suppression was introduced. The initial compatibility date exceeded the installed workerd binary; the final configuration uses its supported `2026-10-19` date. Production domain/DNS/TLS remain unverified. Indexing remains disabled pending release/content acceptance.

## Final foundation review — 2026-10-22

Reviewed setup scripts, dependency boundaries, source/component layout, current Sketch notes, locale isolation, route-owned SEO and generated-file hygiene. Fixed the outdated NativeSelect language switcher: the current source requires moduix Menu with RadioItemGroup links, native names, `lang`/`hreflang`, current selection and an accessible button name. Removed the now-unused locale guard. Aligned `@types/node` with the tested Node 24 runtime and moved the Paraglide compiler to devDependencies. Added seven repeatable Worker HTTP smoke tests (`pnpm test:smoke`) and made `deploy:dry-run` rebuild first, so it cannot package a stale build by accident. No custom UI primitive, generator or deployment pipeline was introduced.

Final review checks: `pnpm check` (ten foundation tests), rebuilding `pnpm deploy:dry-run`, seven smoke tests against the new local Worker and Safari's Menu selection RU → DE. Production metadata, six localized 404 responses, sitemap/robots and immutable asset caching pass. No critical foundation finding remains. This foundation review preceded the iteration-two implementation below; it is retained as dated setup evidence.

## Superseded implementation

The previous MVP was removed before the current foundation. Its layout, Rsbuild dependency choices, interactive illustrations and checks do not verify or constrain the new implementation; use the current website README and live Sketch notes.

## Iteration-two implementation and review — 2026-10-23

Source: live `Monny.sketch → 05 · Website`, desktop/mobile landing, 404, Drawer, installation and language-menu states plus implementation notes. Source was not edited/saved. Assets in `apps/website/src/assets/product/` are intentional shipped design illustrations, exported at 2x with WebP/PNG alternatives; smaller CPU/popover WebP sources support narrow displays. Intrinsic dimensions reflect the actual exports, including Sketch's existing crop. Example readings are labeled; no live account data or agent verification captures are versioned.

The implementation follows section order, dark semantic colors, system fonts, layout widths and responsive stacking. Uses moduix Button, Menu, Drawer, Badge, Card, Tag, Tabs/Indicator, Clipboard/Tooltip, Accordion, Progress, Slider, Switch and Empty. Static installation steps use an ordered list; the current library's 48 px Button size is `xl`, despite Sketch's `lg` annotation. Gallery Battery reuses the current native-limit illustration instead of the deferred Discharge/helper screen. Download availability and the 100%-disables-limit explanation are factual additions to the source. No libraries, custom generators, deployment systems or app code were added.

Review fixes: removed repeated popover cropping; corrected intrinsic export ratios; centered/scroll-enabled gallery tabs; supplied built-in tab indicators; removed unintended panel borders; fixed Clipboard's default full width squeezing the command; localized its accessible name and Terminal tab; added visible copy tooltip/status and a horizontal Rebind card. The battery demo keeps its example charge at 80% while the selected limit marker changes, and labels 100% as limit off. It never changes system charging.

Verification on the local production Worker: `pnpm check` (format, lint, TypeScript, ten tests), `pnpm build`, seven `pnpm test:smoke` HTTP tests, `pnpm exec wrangler deploy --dry-run`, and `git diff --check`. Smoke checks now cover the final localized section headings, single H1, all anchors, lazy/WebP markup, copy labels and closed FAQ answer content in addition to SEO/404/caching. Local logs stay outside the repository. Upstream `@theme`/sourcemap warnings remain; the landing chunk is about 171 kB gzip and triggers Vite's 500 kB raw-size advisory.

Safari checks: desktop hero/404 and installation screenshots against Sketch; Terminal/System Settings content switching and copy confirmation; gallery Memory/Disk content; language-menu checked state and EN → RU from the Drawer; localized 404 → home with the home title restored. Narrow layout/Drawer were exercised with page zoom, not a physical phone or a calibrated 390 px viewport. Native background captures retained the initial tab indicator/text transition while accessibility selection and the image changed; an active-window check remains necessary, and this is not claimed visually accepted. Browser coordinate/resize capture intermittently failed, so no exact-pixel or full keyboard/VoiceOver claim is made. One stale-preview CSS preload failure while replacing build files was cleared by restarting the preview and reloading; the subsequent 404 → home transition succeeded.

## Next handoff

Review the finished local site against the saved desktop/390 px frames in an active browser, especially tab indicators, narrow overflow, keyboard/VoiceOver and long-language copy. Obtain native-speaker acceptance for the five translations. Then set a verified public DMG URL and enable indexing when release/content acceptance is complete. Publish only on a separate request; verify production DNS/TLS/redirects afterward. App/DMG work remains independent.
