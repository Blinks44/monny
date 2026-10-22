// Run against `pnpm build && pnpm preview --port 4173 --strictPort`.
import assert from 'node:assert/strict'
import { test } from 'node:test'
import settings from '../../project.inlang/settings.json' with { type: 'json' }
import { site } from '../config/site.ts'

const origin = process.env.WEBSITE_TEST_ORIGIN ?? 'http://127.0.0.1:4173'
const productionOrigin = site.origin

function localePath(locale: string) {
  return locale === settings.baseLocale ? '/' : `/${locale}/`
}

for (const locale of settings.locales) {
  test(`Worker serves ${locale} HTML and localized 404 with correct SEO`, async () => {
    const path = localePath(locale)
    const response = await fetch(new URL(path, origin))
    assert.equal(response.status, 200)
    const html = await response.text()
    assert.ok(html.includes(`lang="${locale}"`))
    assert.equal(html.match(/<title>/g)?.length, 1)
    assert.equal(html.match(/name="description"/g)?.length, 1)
    assert.equal(html.match(/rel="canonical"/g)?.length, 1)
    assert.ok(html.includes(`rel="canonical" href="${productionOrigin}${path}"`))
    assert.equal(html.match(/hrefLang=/g)?.length, settings.locales.length + 1)
    const jsonLd = html.match(/<script type="application\/ld\+json">(.*?)<\/script>/)?.[1]
    assert.ok(jsonLd)
    assert.equal(JSON.parse(jsonLd).inLanguage, locale)
    const missing = await fetch(new URL(`${path}missing-page/`, origin))
    assert.equal(missing.status, 404)
    assert.match(missing.headers.get('x-robots-tag') ?? '', /noindex/)
    const missingHtml = await missing.text()
    assert.ok(missingHtml.includes(`lang="${locale}"`))
    assert.ok(!missingHtml.includes('rel="canonical"'))
    assert.ok(!missingHtml.includes('application/ld+json'))
  })
}

test('Worker serves crawler files and immutable hashed assets', async () => {
  const robots = await fetch(new URL('/robots.txt', origin))
  assert.equal(robots.status, 200)
  assert.ok((await robots.text()).includes(`Sitemap: ${productionOrigin}/sitemap.xml`))
  const sitemap = await fetch(new URL('/sitemap.xml', origin))
  assert.equal(sitemap.status, 200)
  assert.match(sitemap.headers.get('content-type') ?? '', /xml/)
  const xml = await sitemap.text()
  assert.equal(xml.match(/<loc>/g)?.length, settings.locales.length)
  for (const locale of settings.locales)
    assert.ok(xml.includes(`${productionOrigin}${localePath(locale)}</loc>`))
  const html = await (await fetch(origin)).text()
  const asset = html.match(/href="(\/assets\/[^"]+\.css)"/)?.[1]
  assert.ok(asset)
  const response = await fetch(new URL(asset, origin))
  assert.equal(response.status, 200)
  assert.match(response.headers.get('cache-control') ?? '', /immutable/)
})
