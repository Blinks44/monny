import fs from 'node:fs'
import path from 'node:path'
import { describe, expect, it } from 'vitest'
import { locales } from '@/config/locales'
import { pageHead, sitemap } from '@/integrations/seo'

describe('website foundation', () => {
  it('generates sitemap with all supported locales', () => {
    const xml = sitemap()
    expect(xml).toContain('https://monny.moduix.dev/')
    for (const locale of locales) {
      expect(xml).toContain(`hreflang="${locale}"`)
    }
  })

  it('builds localized head metadata for every locale', () => {
    for (const locale of locales) {
      const head = pageHead(locale)
      expect(head.meta.length).toBeGreaterThan(5)
      expect(head.links.length).toBeGreaterThan(2)
    }
  })

  it('keeps identical message keys across all 6 locale catalogs', () => {
    const dir = path.resolve(process.cwd(), 'src/integrations/i18n/messages')
    const enKeys = Object.keys(
      JSON.parse(fs.readFileSync(path.join(dir, 'en.json'), 'utf8')),
    ).sort()
    for (const locale of locales) {
      const data = JSON.parse(fs.readFileSync(path.join(dir, `${locale}.json`), 'utf8'))
      expect(Object.keys(data).sort()).toEqual(enKeys)
    }
  })
})
