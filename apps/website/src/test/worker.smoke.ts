// Run against `pnpm build && pnpm preview --port 4173 --strictPort` or production origin.
import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { test } from 'node:test'
import settings from '../../project.inlang/settings.json' with { type: 'json' }
import { siteRoutes } from '../config/locales.ts'
import { site } from '../config/site.ts'

const origin = process.env.WEBSITE_TEST_ORIGIN ?? 'http://127.0.0.1:4173'
const productionOrigin = site.origin

function localePath(locale: string, routePath = '/') {
  const normalized = routePath.endsWith('/') ? routePath : `${routePath}/`
  if (locale === settings.baseLocale) return normalized
  return normalized === '/' ? `/${locale}/` : `/${locale}${normalized}`
}

for (const locale of settings.locales) {
  test(`Worker serves ${locale} HTML and SEO metadata`, async () => {
    const path = localePath(locale)
    const response = await fetch(new URL(path, origin))
    assert.equal(response.status, 200)
    const html = await response.text()
    const messages = JSON.parse(
      await readFile(
        new URL(`../integrations/i18n/messages/${locale}.json`, import.meta.url),
        'utf8',
      ),
    )
    assert.equal(html.match(/<h1\b/g)?.length, 1)
    for (const key of [
      'heroTitleLine1',
      'whoTitle',
      'featuresTitle',
      'bentoTitle',
      'replacesTitle',
      'faqTitle',
      'ctaTitle',
    ]) {
      assert.ok(html.includes(messages[key]), `Missing localized heading: ${locale}/${key}`)
    }
    for (const id of ['top', 'ai-quotas', 'features', 'bento', 'replaces', 'install', 'faq']) {
      assert.ok(html.includes(`id="${id}"`), `Missing section #${id}`)
    }
    assert.ok(html.includes(site.brewCommand))
    assert.ok(html.includes(`lang="${locale}"`))
    assert.equal(html.match(/<title>/g)?.length, 1)
    assert.equal(html.match(/name="description"/g)?.length, 1)
    assert.equal(html.match(/rel="canonical"/g)?.length, 1)
    assert.ok(html.includes(`rel="canonical" href="${productionOrigin}${path}"`))
    assert.equal(html.match(/hrefLang=/g)?.length, settings.locales.length + 1)
    const jsonLd = html.match(/<script type="application\/ld\+json">(.*?)<\/script>/)?.[1]
    assert.ok(jsonLd)
    assert.equal(JSON.parse(jsonLd).inLanguage, locale)
  })
}

test('Worker serves robots.txt, sitemap.xml, and hashed CSS', async () => {
  const robots = await fetch(new URL('/robots.txt', origin))
  assert.equal(robots.status, 200)
  assert.ok((await robots.text()).includes(`Sitemap: ${productionOrigin}/sitemap.xml`))
  const sitemap = await fetch(new URL('/sitemap.xml', origin))
  assert.equal(sitemap.status, 200)
  assert.match(sitemap.headers.get('content-type') ?? '', /xml/)
  const xml = await sitemap.text()
  assert.equal(xml.match(/<loc>/g)?.length, siteRoutes.length * settings.locales.length)
  for (const route of siteRoutes) {
    for (const locale of settings.locales) {
      assert.ok(xml.includes(`${productionOrigin}${localePath(locale, route)}</loc>`))
    }
  }
  const html = await (await fetch(origin)).text()
  const asset = html.match(/href="(\/assets\/[^"]+\.css)"/)?.[1]
  assert.ok(asset)
  const response = await fetch(new URL(asset, origin))
  assert.equal(response.status, 200)
})
