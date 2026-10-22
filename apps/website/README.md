# Monny website

TanStack Start, React 19 and TypeScript, built with Vite for Cloudflare Workers at **https://monny.moduix.dev**. This is iteration one: the application foundation with a minimal landing/404 shell. The full design transfer is iteration two, from **Monny.sketch → 05 · Website**, including its implementation notes. The previous MVP was removed in commit `8c4b4e6`.

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

The website is dark only, as specified in Sketch. `styles/tokens.css` maps the reviewed Sketch colors to moduix semantic tokens and `--monny-metric-*` variables. Keep control sizing/radii/spacing in moduix; product CSS owns layout and app-specific illustrations. System fonts avoid external font requests. Inspect the live Sketch design again before implementing final sections, responsive states or assets.

## Localization and SEO

Paraglide owns locale definitions in `project.inlang/settings.json` and compiles six JSON message catalogs under `src/integrations/i18n/messages/`. Use generated `m.message()` functions. Generated files stay ignored. URL-only locale resolution (`url`, then `baseLocale`) is deterministic for visitors and crawlers, with no locale cookie or automatic language redirect.

English is `/`; the others are `/ru/`, `/de/`, `/fr/`, `/es/`, `/zh-Hans/`. Canonical URLs use trailing slashes consistently. TanStack rewrites via Paraglide's `deLocalizeUrl`/`localizeUrl`; the Worker wraps the original request in `paraglideMiddleware`, preserving per-request locale isolation. The language switcher uses moduix Menu with a RadioItemGroup of native-language links (`lang`/`hreflang`) and a checked current locale. Its button names the language and current selection for assistive technology; choosing a link loads that localized home document. Internal links use TanStack `Link`.

The document includes localized titles/descriptions, `lang`, canonical, six `hreflang` links plus `x-default`, Open Graph, Twitter summary and SoftwareApplication JSON-LD without invented price, ratings or release URL. `/robots.txt` and `/sitemap.xml` come from the same site/locale configuration. Unknown paths return HTTP 404 with localized copy and `noindex`, without home canonical/structured data.

**Before release:** set `site.indexingEnabled` to `true` only after replacing the shell with the finished design/copy. Until then, HTML meta and response headers use `noindex, follow`. The current square social image/favicon is the shipped app icon; a finished share image can replace it during design transfer. Add the real release download only when a public DMG exists. Preserve the first-launch notice from Sketch until notarization.

## Design implementation handoff

The foundation is ready for the next agent. Read the repository instructions, `docs/tasks/WEB-001-landing-page.md` and the live `05 · Website` frames/notes, then replace the minimal page bodies and shared header with the final design. Keep the existing routing, URL-only Paraglide strategy and route-owned SEO: the index route owns home metadata; the root provides the missing-page fallback. Recheck a client transition from 404 to home so its title/canonical update. Reuse the language Menu; when adding footer/Drawer uses, set their popup placement upward as specified in Sketch. Add final section copy in all catalogs, respect reduced motion and finish keyboard/mobile checks. A real release URL, final image assets and enabling indexing belong to that implementation/release work. Deployment remains a separate authorized step.

## Cloudflare deployment

`wrangler.jsonc` declares a Worker Custom Domain for `monny.moduix.dev`, with `workers.dev` and preview URLs disabled. It uses the official Cloudflare Vite plugin, `nodejs_compat`, and compatibility date `2026-10-19`, the latest date supported by the installed workerd binary when verified. No database or other bindings are needed. Hashed browser assets receive immutable caching through `public/_headers`.

When publication is requested, authenticate Wrangler to the Cloudflare account that owns the active `moduix.dev` zone, then run `pnpm deploy`. Custom Domains let Cloudflare manage DNS and TLS for this subdomain; no additional domain purchase is required. This configuration has only been tested locally and with `--dry-run`; DNS/TLS and the live domain remain unverified. Do not use the DNS apex or change `moduix.dev`'s existing application. In Workers Builds, set the root directory to `apps/website`, build command to `pnpm build` and deploy command to `pnpm exec wrangler deploy` after configuring dependency installation.

Known upstream build warnings: moduix 3.0.1's shared CSS includes Tailwind's `@theme` metadata even in its CSS Modules foundation; Lightning CSS reports it as unknown. Vite also reports a CSS sourcemap warning. Production builds and the verified styles work; no Tailwind dependency or library patch is introduced to hide these warnings.

References: [Cloudflare's TanStack Start setup](https://developers.cloudflare.com/workers/framework-guides/web-apps/tanstack-start/), [Paraglide's official TanStack integration](https://paraglidejs.com/tanstack-start), [moduix setup](https://moduix.dev/docs/quick-start), [moduix themes](https://moduix.dev/docs/themes), [Oxlint configuration](https://oxc.rs/docs/guide/usage/linter/config).
