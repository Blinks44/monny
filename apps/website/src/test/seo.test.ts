import { describe, expect, it } from 'vitest'
import { localePath, locales, siteRoutes } from '@/config/locales'
import { getAlternativeContent, getGuideContent } from '@/content/seo'
import { pageHead, sitemap } from '@/integrations/seo'

describe('SEO infrastructure', () => {
  it('normalizes localized route paths with trailing slashes', () => {
    expect(localePath('en')).toBe('/')
    expect(localePath('ru')).toBe('/ru/')
    expect(localePath('en', '/alternatives/istat-menus')).toBe('/alternatives/istat-menus/')
    expect(localePath('ru', '/alternatives/istat-menus/')).toBe('/ru/alternatives/istat-menus/')
    expect(localePath('de', '/guides/ai-coding-quotas')).toBe('/de/guides/ai-coding-quotas/')
  })

  it('generates sitemap entries for every route and locale', () => {
    const xml = sitemap()
    const locs = xml.match(/<loc>.*?<\/loc>/g) ?? []
    expect(locs).toHaveLength(siteRoutes.length * locales.length)
    expect(xml).toContain('https://monny.moduix.dev/alternatives/istat-menus/')
    expect(xml).toContain('https://monny.moduix.dev/ru/alternatives/aldente/')
    expect(xml).toContain('https://monny.moduix.dev/guides/ai-coding-quotas/')
    expect(xml).toContain('https://monny.moduix.dev/zh-Hans/guides/port-pid-finder/')
  })

  it('emits SoftwareApplication and FAQPage JSON-LD on landing head', () => {
    const head = pageHead('en', {
      path: '/',
      includeSoftwareApplication: true,
      faq: [{ question: 'Q1?', answer: 'A1.' }],
    })
    const types = head.scripts.map((s) => (JSON.parse(s.children) as { '@type': string })['@type'])
    expect(types).toEqual(['SoftwareApplication', 'FAQPage'])
    expect(head.links.find((l) => l.rel === 'canonical')?.href).toBe('https://monny.moduix.dev/')
  })

  it('emits BreadcrumbList and canonical without SoftwareApplication on subpages', () => {
    const head = pageHead('ru', {
      path: '/alternatives/aldente/',
      title: 'AlDente Alt',
      description: 'Desc',
      breadcrumbs: [
        { name: 'Monny', path: '/' },
        { name: 'AlDente', path: '/alternatives/aldente/' },
      ],
    })
    const types = head.scripts.map((s) => (JSON.parse(s.children) as { '@type': string })['@type'])
    expect(types).toEqual(['BreadcrumbList'])
    expect(head.links.find((l) => l.rel === 'canonical')?.href).toBe(
      'https://monny.moduix.dev/ru/alternatives/aldente/',
    )
  })

  it('omits canonical and JSON-LD on notFound pages and marks noindex', () => {
    const head = pageHead('en', { notFound: true })
    expect(head.links).toHaveLength(0)
    expect(head.scripts).toHaveLength(0)
    expect(head.meta.find((entry) => 'name' in entry && entry.name === 'robots')).toEqual({
      name: 'robots',
      content: 'noindex, follow',
    })
  })

  it('provides localized content for all 6 locales and 4 SEO subpages', () => {
    for (const locale of locales) {
      for (const slug of ['istat-menus', 'aldente'] as const) {
        const alt = getAlternativeContent(locale, slug)
        expect(alt.path).toMatch(/\/$/)
        expect(alt.headline.length).toBeGreaterThan(10)
        expect(alt.rows.length).toBeGreaterThanOrEqual(6)
      }
      for (const slug of ['ai-coding-quotas', 'port-pid-finder'] as const) {
        const guide = getGuideContent(locale, slug)
        expect(guide.path).toMatch(/\/$/)
        expect(guide.headline.length).toBeGreaterThan(10)
        expect(guide.cards).toHaveLength(3)
        expect(guide.steps).toHaveLength(4)
        expect(guide.guarantees).toHaveLength(3)
      }
    }
  })
})
