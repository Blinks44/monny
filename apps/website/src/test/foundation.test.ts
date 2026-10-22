import { describe, expect, it } from 'vitest'
import { localePath, locales } from '@/config/locales'
import { site } from '@/config/site'
import de from '@/integrations/i18n/messages/de.json'
import en from '@/integrations/i18n/messages/en.json'
import es from '@/integrations/i18n/messages/es.json'
import fr from '@/integrations/i18n/messages/fr.json'
import ru from '@/integrations/i18n/messages/ru.json'
import zh from '@/integrations/i18n/messages/zh-Hans.json'
import { m } from '@/integrations/i18n/paraglide/messages'
import { deLocalizeUrl, getLocale, localizeUrl } from '@/integrations/i18n/paraglide/runtime'
import { paraglideMiddleware } from '@/integrations/i18n/paraglide/server'
import { pageHead, sitemap } from '@/integrations/seo'

describe('localized public pages', () => {
  it('has complete, nonempty messages in every app language', () => {
    for (const messages of [en, ru, de, fr, es, zh]) {
      expect(Object.keys(messages).sort()).toEqual(Object.keys(en).sort())
      expect(Object.values(messages).every((message) => message.trim().length > 0)).toBe(true)
    }
  })

  it.each(locales)('round-trips the %s landing URL through Paraglide', (locale) => {
    const url = new URL(localePath(locale), site.origin)
    expect(deLocalizeUrl(url).pathname).toBe('/')
    expect(localizeUrl(new URL('/', site.origin), { locale }).pathname).toBe(localePath(locale))
    const head = pageHead(locale)
    expect(head.links).toContainEqual({ rel: 'canonical', href: url.href })
    expect(head.links.filter((link) => link.rel === 'alternate')).toHaveLength(7)
    expect(head.meta).toContainEqual({
      name: 'description',
      content: m.metaDescription({}, { locale }),
    })
    expect(JSON.parse(head.scripts[0]?.children ?? '{}')).toMatchObject({
      '@type': 'SoftwareApplication',
      inLanguage: locale,
    })
  })

  it('does not canonicalize a missing page to the homepage', () => {
    const head = pageHead('ru', true)
    expect(head.links).toEqual([])
    expect(head.scripts).toEqual([])
    expect(head.meta).toContainEqual({
      name: 'robots',
      content: 'noindex, follow',
    })
  })

  it('lists only the six real landing URLs in the sitemap', () => {
    const xml = sitemap()
    expect(xml.match(/<loc>/g)).toHaveLength(6)
    for (const locale of locales)
      expect(xml).toContain(`<loc>${site.origin}${localePath(locale)}</loc>`)
  })

  it('isolates concurrent SSR languages without cookies or shared global locale', async () => {
    const results = await Promise.all(
      locales.map((locale) =>
        paraglideMiddleware(new Request(`${site.origin}${localePath(locale)}`), async () => {
          await Promise.resolve()
          return new Response(JSON.stringify({ locale: getLocale(), title: m.metaTitle() }))
        }).then((response) => response.json()),
      ),
    )
    expect(results).toEqual(
      locales.map((locale) => ({ locale, title: m.metaTitle({}, { locale }) })),
    )
  })
})
