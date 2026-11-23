# Monny Website

Public landing page for [Monny](https://monny.moduix.dev), built with TanStack Start, React 19, `@moduix/react`, Paraglide i18n (6 languages), and Cloudflare Workers.

## Commands

```sh
pnpm install
pnpm dev              # local dev server on http://127.0.0.1:3000
pnpm check            # paraglide compile, format check, oxlint, tsc, vitest
pnpm build            # production client + SSR worker bundle
pnpm deploy           # check, build, and deploy to monny.moduix.dev
```

## Notes

- Live release metadata (`version`, `Monny.dmg`, `SHA256SUMS.txt`) is loaded server-side from GitHub Releases in `src/integrations/releases.ts` with a 15-minute cache and graceful fallback.
- Product screenshots live in `public/screenshots/` as optimized WebP files; vector AI tool marks live in `public/logos/`.
