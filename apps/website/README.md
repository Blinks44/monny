# Monny website

The public landing page: one route, rendered on the server with [TanStack Start](https://tanstack.com/start) on Rsbuild. English is served at `/`; Russian, German, French, Spanish and Simplified Chinese at `/ru`, `/de`, `/fr`, `/es` and `/zh`, the same six languages as the app. Unknown paths render the 404 page with status 404. The structure follows the Rebind website.

```sh
pnpm install
pnpm dev      # http://localhost:3000 (the next free port if 3000 is taken)
pnpm build    # production build and type check
pnpm preview  # build and run it locally in the Cloudflare Workers runtime (wrangler dev)
pnpm deploy   # build and publish to https://monny.moduix.dev
```

**Hosting**: the site is a Cloudflare Worker (`wrangler.jsonc`): `dist/client` is served as static assets and `dist/server/index.js` renders the rest. `wrangler deploy` attaches the custom domain `monny.moduix.dev` (the `moduix.dev` zone is on the same Cloudflare account) and creates its DNS record and certificate. The first run opens a browser to sign in to Cloudflare (`wrangler login`). TanStack Start's Cloudflare guide covers only Vite, so `rsbuild.config.ts` builds the server environment for a web worker in production (`pnpm dev` still runs in Node).

- **Copy** lives in `messages/<locale>.json` and uses the app's own terms (check `Localizable.xcstrings` before renaming one: «Лимит заряда», „Ladelimit“, « Limite de charge »…). Describe only what the app ships ([SPEC](../../docs/SPEC.md)): no Discharge, sailing or calibration, which are deferred. [Paraglide](https://inlang.com/m/gerre34r/library-inlang-paraglideJs) compiles them into `src/paraglide/` (generated, not versioned) on every dev start and build; add a language in `project.inlang/settings.json` and the `urlPatterns` in `rsbuild.config.ts`.
- **Layout**: `src/components/` holds reusable pieces and `src/sections/` the page's blocks, each in its own folder (`components/popover/Popover.tsx` next to `Popover.module.css`) and exported from the top-level `index.ts`; `src/lib/` holds data, number formatting and the release server function; `src/routes/` only composes sections and sets the head.
- **App renditions**: the menu bar popover, the dashboard window and the charge-limit control are HTML versions of the Monny.sketch frames with fixed sample values. They are built from ready parts: moduix Tabs, Switch, Slider, ProgressCircular (ring gauges), ProgressLinear (bars) and Chart, which draws with [TanStack Charts](https://tanstack.com/charts) and its tooltip; `d3-shape` gives the smooth curve. `@tanstack/charts` is pinned to 1.0.0, the version moduix 3.0 is built against: with 1.1.0 the moduix chart tooltip loses its background. Numbers, units and dates go through `src/lib/format.ts` (`Intl`), so they read naturally in each language.
- **Styling**: components come from [moduix](https://moduix.dev) (`@moduix/react`), including its reset; animation is [Motion](https://motion.dev). `src/styles/theme.css` is the only global stylesheet: it defines Monny's colors with `light-dark()`, mirroring `apps/monny/monny/DesignSystem/Theme.swift` (change a token in both places), and maps them onto moduix tokens so Tabs, Switch, Slider, Progress, Chart, Card and Clipboard take the app's look.
- **First launch**: the Install section explains the missing notarization and offers the `xattr` command through moduix Clipboard, matching the root README. Remove the callout and the related FAQ entry once releases are notarized.
- **Settings** are in `src/lib/site.ts`. `githubRepo` is `Blinks44/monny`: the download button links to the latest stable release DMG (`src/lib/release.ts`, a server function). `url` is the production origin used for canonical, hreflang and Open Graph URLs. No release/DMG or a failed API request leaves Download disabled. Release metadata is cached for up to 10 minutes. This does not publish the app or site.
- Icons are Lucide, not SF Symbols: the SF Symbols license does not cover use on a website. `public/favicon.svg` is the app icon drawn from `AppIcon.icon`; the AI service marks in `public/` are the app's own assets and only identify those services.
