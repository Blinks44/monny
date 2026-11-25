import {
  defaultLocale,
  type Locale,
  localePath,
  locales,
  openGraphLocales,
  siteRoutes,
} from '@/config/locales'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'

export interface FaqEntry {
  question: string
  answer: string
}

export interface BreadcrumbItem {
  name: string
  path: string
}

export interface PageHeadOptions {
  notFound?: boolean
  path?: string
  title?: string
  description?: string
  includeSoftwareApplication?: boolean
  faq?: FaqEntry[]
  breadcrumbs?: BreadcrumbItem[]
}

export function pageHead(locale: Locale, options: boolean | PageHeadOptions = false) {
  const opts: PageHeadOptions = typeof options === 'boolean' ? { notFound: options } : options
  const notFound = opts.notFound ?? false
  const routePath = opts.path ?? '/'

  const title = notFound
    ? m.notFoundTitle({}, { locale })
    : (opts.title ?? m.metaTitle({}, { locale }))
  const description = notFound
    ? m.notFoundDescription({}, { locale })
    : (opts.description ?? m.metaDescription({}, { locale }))
  const url = `${site.origin}${localePath(locale, routePath)}`

  const scripts: Array<{ type: string; children: string }> = []

  if (!notFound) {
    if (opts.includeSoftwareApplication ?? routePath === '/') {
      scripts.push({
        type: 'application/ld+json',
        children: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'SoftwareApplication',
          name: site.name,
          url,
          description,
          inLanguage: locale,
          operatingSystem: 'macOS 15+',
          applicationCategory: 'UtilitiesApplication',
          offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
          author: {
            '@type': 'Person',
            name: site.author.name,
            sameAs: [site.author.x, 'https://github.com/Blinks44'],
          },
        }),
      })
    }

    if (opts.faq && opts.faq.length > 0) {
      scripts.push({
        type: 'application/ld+json',
        children: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          mainEntity: opts.faq.map((item) => ({
            '@type': 'Question',
            name: item.question,
            acceptedAnswer: {
              '@type': 'Answer',
              text: item.answer,
            },
          })),
        }),
      })
    }

    if (opts.breadcrumbs && opts.breadcrumbs.length > 0) {
      scripts.push({
        type: 'application/ld+json',
        children: JSON.stringify({
          '@context': 'https://schema.org',
          '@type': 'BreadcrumbList',
          itemListElement: opts.breadcrumbs.map((crumb, index) => ({
            '@type': 'ListItem',
            position: index + 1,
            name: crumb.name,
            item: `${site.origin}${localePath(locale, crumb.path)}`,
          })),
        }),
      })
    }
  }

  return {
    meta: [
      { title },
      { name: 'description', content: description },
      {
        name: 'robots',
        content: notFound || !site.indexingEnabled ? 'noindex, follow' : 'index, follow',
      },
      { property: 'og:type', content: 'website' },
      { property: 'og:site_name', content: site.name },
      { property: 'og:title', content: title },
      { property: 'og:description', content: description },
      { property: 'og:locale', content: openGraphLocales[locale] },
      ...(!notFound ? [{ property: 'og:url', content: url }] : []),
      { property: 'og:image', content: `${site.origin}/og-image.jpg` },
      { property: 'og:image:width', content: '2400' },
      { property: 'og:image:height', content: '1260' },
      { property: 'og:image:alt', content: 'Monny for macOS' },
      { name: 'twitter:card', content: 'summary_large_image' },
      { name: 'twitter:site', content: site.author.xHandle },
      { name: 'twitter:creator', content: site.author.xHandle },
      { name: 'twitter:title', content: title },
      { name: 'twitter:description', content: description },
      { name: 'twitter:image', content: `${site.origin}/og-image.jpg` },
      { name: 'twitter:image:alt', content: 'Monny for macOS' },
    ],
    links: notFound
      ? []
      : [
          { rel: 'canonical', href: url },
          ...locales.map((value) => ({
            rel: 'alternate',
            hrefLang: value,
            href: `${site.origin}${localePath(value, routePath)}`,
          })),
          {
            rel: 'alternate',
            hrefLang: 'x-default',
            href: `${site.origin}${localePath(defaultLocale, routePath)}`,
          },
        ],
    scripts,
  }
}

export function sitemap() {
  const entries = siteRoutes.flatMap((routePath) => {
    const alternates = locales
      .map(
        (locale) =>
          `<xhtml:link rel="alternate" hreflang="${locale}" href="${site.origin}${localePath(locale, routePath)}"/>`,
      )
      .join('')
    const defaultHref = `${site.origin}${localePath(defaultLocale, routePath)}`
    return locales.map(
      (locale) =>
        `<url><loc>${site.origin}${localePath(locale, routePath)}</loc>${alternates}<xhtml:link rel="alternate" hreflang="x-default" href="${defaultHref}"/></url>`,
    )
  })
  return `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">${entries.join('')}</urlset>`
}
