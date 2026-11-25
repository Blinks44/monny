import { createFileRoute } from '@tanstack/react-router'
import { GuidePage } from '@/components/GuidePage'
import type { Locale } from '@/config/locales'
import { getGuideContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'

export const Route = createFileRoute('/guides/ai-coding-quotas')({
  loader: () => getLatestRelease(),
  head: () => {
    const locale = getLocale() as Locale
    const content = getGuideContent(locale, 'ai-coding-quotas')
    return pageHead(locale, {
      path: content.path,
      title: content.metaTitle,
      description: content.metaDescription,
      breadcrumbs: [
        { name: m.seoBreadcrumbHome({}, { locale }), path: '/' },
        { name: m.seoBreadcrumbGuides({}, { locale }), path: content.path },
        { name: content.breadcrumbLabel, path: content.path },
      ],
    })
  },
  component: GuideRoute,
})

function GuideRoute() {
  const release = Route.useLoaderData()
  return <GuidePage slug="ai-coding-quotas" release={release} />
}
