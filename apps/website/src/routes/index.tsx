import { createFileRoute } from '@tanstack/react-router'
import { useState } from 'react'
import { AiProvidersStrip } from '@/components/AiProvidersStrip'
import { BentoGrid } from '@/components/BentoGrid'
import { FaqSection } from '@/components/FaqSection'
import { FeatureShowcase, type FeatureTabId } from '@/components/FeatureShowcase'
import { FinalCta } from '@/components/FinalCta'
import { Footer } from '@/components/Footer'
import { Hero } from '@/components/Hero'
import { InstallSection } from '@/components/InstallSection'
import { Navbar } from '@/components/Navbar'
import { NativeMetrics } from '@/components/NativeMetrics'
import { PrivacyPopoverSection } from '@/components/PrivacyPopoverSection'
import { getLatestRelease } from '@/integrations/releases'
import { useRevealObserver } from '@/lib/reveal'
import { useTheme } from '@/lib/theme'

export const Route = createFileRoute('/')({
  loader: () => getLatestRelease(),
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
        <FeatureShowcase theme={theme} activeTab={featureTab} onTabChange={setFeatureTab} />
        <BentoGrid theme={theme} />
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
