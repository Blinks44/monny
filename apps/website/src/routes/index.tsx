import { createFileRoute } from '@tanstack/react-router'
import { LandingPage } from '@/features/landing/landing-page'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { pageHead } from '@/integrations/seo'

export const Route = createFileRoute('/')({
  head: () => pageHead(getLocale()),
  component: LandingPage,
})
