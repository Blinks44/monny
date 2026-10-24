import { defaultLocale, type Locale, localePath, locales, openGraphLocales } from '@/config/locales'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'

export function pageHead(locale: Locale, notFound = false) {
  const title = notFound ? m.notFoundTitle({}, { locale }) : m.metaTitle({}, { locale })
  const description = notFound
    ? m.notFoundDescription({}, { locale })
    : m.metaDescription({}, { locale })
  const url = `${site.origin}${localePath(locale)}`
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
      { property: 'og:image:alt', content: 'Monny' },
      { name: 'twitter:card', content: 'summary_large_image' },
      { name: 'twitter:title', content: title },
      { name: 'twitter:description', content: description },
      { name: 'twitter:image', content: `${site.origin}/og-image.jpg` },
      { name: 'twitter:image:alt', content: 'Monny' },
    ],
    links: notFound
      ? []
      : [
          { rel: 'canonical', href: url },
          ...locales.map((value) => ({
            rel: 'alternate',
            hrefLang: value,
            href: `${site.origin}${localePath(value)}`,
          })),
          {
            rel: 'alternate',
            hrefLang: 'x-default',
            href: `${site.origin}${localePath(defaultLocale)}`,
          },
        ],
    scripts: notFound
      ? []
      : [
          {
            type: 'application/ld+json',
            children: JSON.stringify({
              '@context': 'https://schema.org',
              '@type': 'SoftwareApplication',
              name: site.name,
              url,
              description,
              inLanguage: locale,
              operatingSystem: 'macOS 26+',
              applicationCategory: 'UtilitiesApplication',
            }),
          },
        ],
  }
}

export function sitemap() {
  const alternates = locales
    .map(
      (locale) =>
        `<xhtml:link rel="alternate" hreflang="${locale}" href="${site.origin}${localePath(locale)}"/>`,
    )
    .join('')
  return `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">${locales.map((locale) => `<url><loc>${site.origin}${localePath(locale)}</loc>${alternates}<xhtml:link rel="alternate" hreflang="x-default" href="${site.origin}/"/></url>`).join('')}</urlset>`
}
