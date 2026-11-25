import { createFileRoute } from '@tanstack/react-router'
import { AlternativePage } from '@/components/AlternativePage'
import type { Locale } from '@/config/locales'
import { getAlternativeContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'

export const Route = createFileRoute('/alternatives/istat-menus')({
  loader: () => getLatestRelease(),
  head: () => {
    const locale = getLocale() as Locale
    const content = getAlternativeContent(locale, 'istat-menus')
    return pageHead(locale, {
      path: content.path,
      title: content.metaTitle,
      description: content.metaDescription,
      breadcrumbs: [
        { name: m.seoBreadcrumbHome({}, { locale }), path: '/' },
        { name: m.seoBreadcrumbAlternatives({}, { locale }), path: content.path },
        { name: content.breadcrumbLabel, path: content.path },
      ],
    })
  },
  component: AlternativeRoute,
})

function AlternativeRoute() {
  const release = Route.useLoaderData()
  return <AlternativePage slug="istat-menus" release={release} />
}
