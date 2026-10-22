# WEB-001: Public landing page

- Updated: 2026-10-22
- Stage: ready_for_implementation (iteration one complete; iteration two is the next slice)
- Owner: unassigned
- Ownership checked: main at `39b3408`; final website review/task note owned by this implementation turn, released at handoff
- Owned surfaces: `apps/website/`, website sections in shared docs; Sketch inspected read-only
- Requirements: [SPEC §10](../SPEC.md#10-public-website), user decisions 2026-10-22; PLAN phase 5
- Code baseline: reviewed foundation committed at main `39b3408`; only the final task-record update remains uncommitted

## Current outcome

Rebuild the rejected MVP in two iterations. **Iteration one is the application foundation**, using TanStack Start/React 19, Vite, moduix CSS Modules/Calm, Lucide, Paraglide, Oxlint/Oxfmt, six-language SSR/SEO, real HTTP 404 and Cloudflare Workers configuration for the confirmed `monny.moduix.dev` domain. Source structure and component folders follow the user's requested contract; see the [website README](../../apps/website/README.md).

**Iteration two is the full design transfer**, from the live `Monny.sketch → 05 · Website`, including responsive layouts, product screenshots, navigation, installation notice, FAQ and download. The current landing and 404 components are deliberately minimal shells. Neither the old MVP nor the Sketch sections are claimed implemented. The shell remains `noindex` until final content is ready. No deployment, DNS change or Sketch edit was performed in this turn. The foundation is now captured in `39b3408`; the agent did not create that commit.

## Acceptance

- [x] React 19/TanStack Start Worker builds with CSS Modules and the requested source structure.
- [x] moduix styles, dark semantic/metric tokens from Sketch, system typography and Lucide imports work. The updated language-menu contract is implemented with real localized links and checked state.
- [x] Paraglide generates type-safe messages for EN/RU/DE/FR/ES/zh-Hans; URL rewrites and request-scoped middleware work.
- [x] Localized server HTML/head, canonical/hreflang, Open Graph/Twitter, SoftwareApplication JSON-LD, robots and sitemap exist; unknown paths return HTTP 404 without a home canonical.
- [x] Oxlint, Oxfmt, TypeScript and ten focused foundation tests pass.
- [x] Production preview runs in workerd; Wrangler packaging succeeds with `--dry-run`.
- [ ] Full design implementation and desktop/mobile review against the live Sketch source.
- [ ] Review final translations, keyboard/assistive technology and responsive behavior.
- [ ] Real release download and first-launch installation flow (remove the notice when notarized).
- [ ] First authorized production deployment; verify DNS, HTTPS, redirects and indexing on `monny.moduix.dev`.

## Design source

Read-only inspection on 2026-10-22: `Monny.sketch → 05 · Website`, desktop/mobile landing and 404, mobile menu, install-alert state and `Website · Implementation notes`. Dark only, moduix Calm with semantic overrides and system typography. Exact source and notes remain in Sketch; [DESIGN](../DESIGN.md#website) is the short locator. No design exports were committed.

## Implementation and verification

Agent-observed 2026-10-22 on macOS 27.0.1 / Node 24.22.0 / pnpm 12.14.0. Commands from `apps/website`: frozen installation and standard Paraglide `prepare`, `pnpm check` (Oxfmt, Oxlint, `tsc --noEmit`, Vitest: 10 tests), `pnpm build`, `pnpm preview --port 4173 --strictPort`, `pnpm deploy:dry-run`. The latter packages locally without uploading or changing domains.

HTTP verification against the production Worker preview: `/`, `/ru/`, `/de/`, `/fr/`, `/es/`, `/zh-Hans/` return 200 with matching HTML `lang`, localized title, one canonical and seven alternate links. `/missing/`, `/ru/missing/` and `/xx/` return 404 with matching error copy and no canonical. Robots, sitemap and app icon return 200 with the expected media types. Unit tests also verify simultaneous SSR requests retain their own locales. Safari verification: styled dark shell, language selector RU → DE, localized 404 and return-home interaction. The navigation review caught a stale 404 title on return home; moving home metadata to the index route fixed its ownership. Desktop screenshots stay local.

Two upstream warnings remain: moduix 3.0.1 includes `@theme` metadata in its shared stylesheet, which Lightning CSS does not recognize; Vite reports a CSS sourcemap warning. No dependency patch, Tailwind addition or warning suppression was introduced. The initial compatibility date exceeded the installed workerd binary; the final configuration uses its supported `2026-10-19` date. Production domain/DNS/TLS remain unverified. Indexing is disabled until iteration two.

## Final foundation review — 2026-10-22

Reviewed setup scripts, dependency boundaries, source/component layout, current Sketch notes, locale isolation, route-owned SEO and generated-file hygiene. Fixed the outdated NativeSelect language switcher: the current source requires moduix Menu with RadioItemGroup links, native names, `lang`/`hreflang`, current selection and an accessible button name. Removed the now-unused locale guard. Aligned `@types/node` with the tested Node 24 runtime and moved the Paraglide compiler to devDependencies. Added seven repeatable Worker HTTP smoke tests (`pnpm test:smoke`) and made `deploy:dry-run` rebuild first, so it cannot package a stale build by accident. No custom UI primitive, generator or deployment pipeline was introduced.

Final review checks: `pnpm check` (ten foundation tests), rebuilding `pnpm deploy:dry-run`, seven smoke tests against the new local Worker and Safari's Menu selection RU → DE. Production metadata, six localized 404 responses, sitemap/robots and immutable asset caching pass. No critical foundation finding remains. The next agent can start the design transfer using the handoff in the website README; final design/mobile/accessibility/translation acceptance and the real domain are still the next iteration's checks.

## Superseded MVP evidence

The prior MVP was committed at `2efcb5c` and removed at `8c4b4e6` before this task began. Its old results do not verify the new implementation. On 2026-10-22 it built with Rsbuild, rendered at 1440/1280/390 px in Light/Dark with Russian/Chinese, returned 404, copied the installation command, and passed local popover/tab/chart-tooltip checks. It used app frames because website frames did not yet exist; the revised website frames now supersede that direction.

MVP-specific findings retained for future illustrations: `Intl` has no `watt` unit; an Ark slider hidden input belongs inside its thumb. Its hand-written ring/bars/sparkline and hover code were replaced by moduix controls/charts; no simulated reading drift or interactive dashboard-range placeholder remained. TanStack Charts 1.0.0 worked with moduix 3.0, while 1.1.0 made its tooltip transparent; that pin is historical evidence, not a current dependency requirement. The hero used a subgrid to align the status item/popover; AI sample values were shared across four service cards. User visual/localization acceptance, real-release download and production runtime were still open when that MVP was retired.

## Next handoff

Implement the website from `Monny.sketch → 05 · Website` on top of this foundation. Inspect the live frames and notes again; use moduix components directly and the existing Paraglide catalogs/tokens. Recheck server/client metadata after navigation, all six locales and true 404, then complete responsive and accessibility review. Publish only when requested. App code/build numbers and the DMG are unaffected by this website-only task.
