# Monny website

TanStack Start, React 19 and TypeScript, built with Vite for Cloudflare Workers at **https://monny.moduix.dev**. Iteration two implements the landing and 404 from **Monny.sketch → 05 · Website**, inspected live on 2026-10-23. It includes the responsive header/Drawer, dashboard gallery, the product demo sections from WEB-002 (menu bar, readings, processes, battery and power, notifications, AI limits, privacy), installation, FAQ, CTA and footer. Product sections share `features/landing/feature-section`. The previous MVP was removed in commit `8c4b4e6`.

## Local development

Requires Node.js 24+ and pnpm 12.14.0. Run from this directory:

```sh
pnpm install --frozen-lockfile
pnpm dev
```

Open the URL printed by Vite (normally http://127.0.0.1:3000). No environment variables, accounts or secrets are required locally. `pnpm check` runs the standard Paraglide `prepare` command before checking types/tests; the Vite plugin compiles messages during dev/build and recompiles on changes. The official inlang message-format plugin is downloaded on first compilation, so the first install/build needs network access. No custom scaffold or generator is maintained.

```sh
pnpm format         # Oxfmt writes formatting
pnpm check          # Paraglide, Oxfmt check, Oxlint, TypeScript, Vitest
pnpm build          # Production browser assets and Worker
pnpm preview        # Production build in local workerd
pnpm deploy:dry-run # Rebuild and package without uploading
```

After `pnpm build`, run `pnpm preview --port 4173 --strictPort` in one terminal and `pnpm test:smoke` in another. The seven HTTP smoke tests check all locale/404 responses, actual rendered metadata/JSON-LD, crawler files and asset caching. To check a different local preview port, run `WEBSITE_TEST_ORIGIN=http://127.0.0.1:4175 pnpm test:smoke`. Rebuild before previewing changed source. Tests cover message completeness, localized URL round trips, SEO, sitemap and concurrent SSR locale isolation.

## Source structure

- `src/assets/`: imported product assets; `public/` contains assets with stable URLs.
- `src/components/`: reusable site components.
- `src/config/`: public site settings, language names and locale mappings.
- `src/features/`: page/section components grouped by feature.
- `src/integrations/`: Paraglide and SEO integration.
- `src/routes/`: thin file routes and the document shell.
- `src/styles/`: shared design tokens; `src/app.css` imports moduix reset/foundation and global base rules.
- `src/test/`, `src/types/`, `src/utils/`: tests, shared types and small utilities when needed. Empty directories reserve the requested structure; do not add abstractions just to fill them.
- `src/env.ts`, `src/router.tsx`, `src/server.ts`, `src/start.ts`: Vite types, router, Worker entry and Start configuration.
- `src/routeTree.gen.ts`: TanStack's generated route tree, versioned for clean-checkout type checking. Never edit manually.

Every product component uses `component-name/ComponentName.tsx`, `ComponentName.module.css`, `index.ts`. Import from that folder, without an application-wide barrel. Route entry files and framework integrations follow their framework conventions.

## Components and design tokens

Use direct package imports such as `@moduix/react/button`, rather than copying library source or wrapping every control. The CSS Modules distribution includes component styles. Calm is the default in `@moduix/react/style.css`; no separate Calm stylesheet or runtime theme provider is needed. Lucide React supplies icons with named imports. Hide decorative icons from accessibility APIs.

The website is dark only, as specified in Sketch. `styles/tokens.css` maps the reviewed Sketch colors to moduix semantic tokens and `--monny-metric-*` variables. Use moduix component tokens in section CSS for the sizing/radii/colors drawn in Sketch; product CSS owns layout and app-specific illustrations. Keep keyboard focus styling in the library; the global focus rule applies only to plain links. System fonts avoid external font requests. Inspect the live Sketch design again before implementing final sections, responsive states or assets.

## Localization and SEO

Paraglide owns locale definitions in `project.inlang/settings.json` and compiles six JSON message catalogs under `src/integrations/i18n/messages/`. Use generated `m.message()` functions. Generated files stay ignored. URL-only locale resolution (`url`, then `baseLocale`) is deterministic for visitors and crawlers, with no locale cookie or automatic language redirect.

English is `/`; the others are `/ru/`, `/de/`, `/fr/`, `/es/`, `/zh-Hans/`. Canonical URLs use trailing slashes consistently. TanStack rewrites via Paraglide's `deLocalizeUrl`/`localizeUrl`; the Worker wraps the original request in `paraglideMiddleware`, preserving per-request locale isolation. The language switcher uses moduix Menu/RadioItemGroup, a localized group label, native-language links (`lang`/`hreflang`), language codes and a trailing checked indicator. Header/footer/Drawer triggers are 36/32/44 px; rows are 36 px or 44 px in the Drawer, with MenuViewport scrolling for short heights. Its button names the language and current selection for assistive technology; choosing a link loads that localized home document. Internal links use TanStack `Link`.

The document includes localized titles/descriptions, `lang`, canonical, six `hreflang` links plus `x-default`, Open Graph, Twitter summary and SoftwareApplication JSON-LD without invented price, ratings or release URL. `/robots.txt` and `/sitemap.xml` come from the same site/locale configuration. Unknown paths return HTTP 404 with localized copy and `noindex`, without home canonical/structured data.

**Release download and indexing:** `site.downloadUrl` is `releases/latest/download/Monny.dmg`, which GitHub redirects to the newest stable release, so releases need no website change; `site.indexingEnabled` is `true`. With `downloadUrl` set to `null`, download actions fall back to the GitHub Releases page and the hero shows the pending-release note; with indexing off, HTML meta/response headers use `noindex, follow`. Link previews (Open Graph and Twitter `summary_large_image`) use `public/og-image.jpg` at 2400×1260; the favicon is the shipped app icon. Preserve the first-launch notice from Sketch until notarization.

## Design transfer and review

Product components use CSS Modules and direct moduix imports. The gallery and installation use Tabs with their built-in indicators; FAQ uses Accordion, the mobile navigation uses Drawer, and Clipboard/Tooltip confirm copying. Static installation instructions use a semantic ordered list rather than an interactive wizard. Buttons drawn at 48 px in Sketch use moduix's current `xl` size (`lg` is 40 px in version 3.0.1). Battery controls change only the local illustration. The battery gallery panel reuses the current native-limit illustration rather than advertising the deferred controls in older app frames.

Source illustrations under `src/assets/product/` were exported from the open Monny document on 2026-10-23: named transparent Export · Web containers in Dark Overview/CPU/AI/Memory/Disk/Network/Sensors and the shadow-padded popover Frame, plus the Rebind cross-link icon. Product images use moduix Image within native `picture`, with WebP sources, PNG fallbacks, intrinsic dimensions and localized alt text. Vite generates 580/1160/2320 px WebP variants for all seven window illustrations and 480/960 px variants for the popover. Context-specific `sizes` lets the browser choose for the rendered width and screen density. Below-fold images load lazily and inactive gallery panels mount on demand. These are design previews with example readings, explicitly labeled as such; they do not contain live account/device captures. Export the named containers rather than Wallpaper parents. Monny/Rebind sources and their website image placements/export notes were corrected and saved on 2026-10-23; Rebind export Frames clip Canvas glow to the app bounds. The export handoff was reviewed with all 13 Monny/Rebind illustrations. Fixed transparent Frame dimensions and 2x PNG/WebP presets agree; keep padding (`trimmed: false`). The popover includes an opaque backing only within the window silhouette and transparent space for its shadow. General verification screenshots remain outside Git.

Checked locally: format/lint/types, 12 tests, rebuilding Worker dry-run packaging and seven production HTTP smoke checks. Final design corrections cover the language popup/Drawer dimensions and first-launch link, source 404 surfaces and the hero caption overlap. Chrome verified the desktop menu and 390×844 Drawer/upward menu with keyboard selection to German. Safari verified localized 404 → home title restoration. A height-capped German mobile full-page capture reviewed battery/AI/install/FAQ wrapping; offscreen lazy images and the page bottom require direct review. Full physical-phone/all-section, keyboard/VoiceOver, reduced-motion and fluent translation acceptance remain in [WEB-001](../../docs/tasks/WEB-001-landing-page.md). Background native input/capture remains intermittent; bounded checks do not establish whole-page pixel acceptance. Section title classes keep footer captions at 12 px.

## Image optimization

Keep the original transparent Sketch PNG exports as source/fallback assets. `vite-imagetools` uses Sharp to resize and encode them automatically during development/build, caching results under the ignored `node_modules/` directory. Each image import declares its widths, WebP format, quality 90 and effort 6, and returns the ready `srcset` string. No custom script, separate optimization command or generated WebP files in `src/` are needed. Replacing a PNG is enough; Vite handles the next dev load/build. Review small text, graphs, dark gradients and shadows after changing exports or encoding settings. Moduix Image renders the result; no image CDN, runtime transformation or Cloudflare Images subscription is required.

Reference: [vite-imagetools](https://github.com/JonasKruckenberg/imagetools/tree/main/packages/vite).

## Cloudflare deployment

`wrangler.jsonc` declares a Worker Custom Domain for `monny.moduix.dev`, with `workers.dev` and preview URLs disabled. It uses the official Cloudflare Vite plugin, `nodejs_compat`, and compatibility date `2026-10-19`, the latest date supported by the installed workerd binary when verified. No database or other bindings are needed. Hashed browser assets receive immutable caching through `public/_headers`.

When publication is requested, authenticate Wrangler to the Cloudflare account that owns the active `moduix.dev` zone, then run `pnpm deploy`. Custom Domains let Cloudflare manage DNS and TLS for this subdomain; no additional domain purchase is required. This configuration has only been tested locally and with `--dry-run`; DNS/TLS and the live domain remain unverified. Do not use the DNS apex or change `moduix.dev`'s existing application. In Workers Builds, set the root directory to `apps/website`, build command to `pnpm build` and deploy command to `pnpm exec wrangler deploy` after configuring dependency installation.

Known upstream build warnings: the landing bundle also crosses Vite’s 500 kB uncompressed chunk advisory (about 171 kB gzip); no threshold suppression or manual chunk framework is used. Other warnings: moduix 3.0.1's shared CSS includes Tailwind's `@theme` metadata even in its CSS Modules foundation; Lightning CSS reports it as unknown. Vite also reports a CSS sourcemap warning. Production builds and the verified styles work; no Tailwind dependency or library patch is introduced to hide these warnings.

References: [Cloudflare's TanStack Start setup](https://developers.cloudflare.com/workers/framework-guides/web-apps/tanstack-start/), [Paraglide's official TanStack integration](https://paraglidejs.com/tanstack-start), [moduix setup](https://moduix.dev/docs/quick-start), [moduix themes](https://moduix.dev/docs/themes), [Oxlint configuration](https://oxc.rs/docs/guide/usage/linter/config).
