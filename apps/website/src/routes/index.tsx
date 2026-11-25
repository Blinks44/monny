import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { AiProvidersStrip } from '@/components/AiProvidersStrip'
import { BentoGrid } from '@/components/BentoGrid'
import { FaqSection, getLandingFaqItems } from '@/components/FaqSection'
import { FeatureShowcase, type FeatureTabId } from '@/components/FeatureShowcase'
import { FinalCta } from '@/components/FinalCta'
import { Footer } from '@/components/Footer'
import { Hero } from '@/components/Hero'
import { InstallSection } from '@/components/InstallSection'
import { NativeMetrics } from '@/components/NativeMetrics'
import { Navbar } from '@/components/Navbar'
import { PrivacyPopoverSection } from '@/components/PrivacyPopoverSection'
import { ReplacesSection } from '@/components/ReplacesSection'
import { WhoItIsForSection } from '@/components/WhoItIsForSection'
import type { Locale } from '@/config/locales'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { getLatestRelease } from '@/integrations/releases'
import { pageHead } from '@/integrations/seo'
import { useRevealObserver } from '@/lib/reveal'
import { useTheme } from '@/lib/theme'

export const Route = createFileRoute('/')({
  loader: () => getLatestRelease(),
  head: () => {
    const locale = getLocale() as Locale
    return pageHead(locale, {
      path: '/',
      includeSoftwareApplication: true,
      faq: getLandingFaqItems(locale),
    })
  },
  component: LandingPage,
})

function LandingPage() {
  const release = Route.useLoaderData()
  const { theme, toggleTheme } = useTheme()
  const [featureTab, setFeatureTab] = useState<FeatureTabId>('battery')

  useRevealObserver()

  return (
    <>
      <Navbar theme={theme} onToggleTheme={toggleTheme} />
      <main>
        <Hero release={release} theme={theme} onToggleTheme={toggleTheme} />
        <AiProvidersStrip theme={theme} />
        <WhoItIsForSection />
        <FeatureShowcase theme={theme} activeTab={featureTab} onTabChange={setFeatureTab} />
        <BentoGrid theme={theme} />
        <ReplacesSection />
        <PrivacyPopoverSection />
        <NativeMetrics />
        <InstallSection release={release} />
        <FaqSection />
        <FinalCta release={release} />
      </main>
      <Footer release={release} onSelectFeature={setFeatureTab} />
    </>
  )
}
