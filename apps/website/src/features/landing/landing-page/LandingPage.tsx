import { Badge } from '@moduix/react/badge'
import { Card } from '@moduix/react/card'
import { Tag } from '@moduix/react/tag'
import { Check, ShieldCheck, UserRoundCheck, Feather, CodeXml } from 'lucide-react'
import { DownloadActions } from '@/components/download-actions'
import { ProductImage } from '@/components/product-image'
import { m } from '@/integrations/i18n/paraglide/messages'
import { HeroSection } from '../hero-section'
import { FeatureGrid } from '../feature-grid'
import { BatteryDemo } from '../battery-demo'
import { DashboardSection } from '../dashboard-section'
import { InstallNotice } from '../install-notice'
import { FaqSection } from '../faq-section'
import { SiteFooter } from '../site-footer'
import styles from './LandingPage.module.css'

export function LandingPage() {
  const checks = [
    [m.batteryCheck1(), m.batteryDetail1()],
    [m.batteryCheck2(), m.batteryDetail2()],
    [m.batteryCheck3(), m.batteryDetail3()],
  ]
  const principles = [
    [ShieldCheck, m.localTitle(), m.localDescription(), 'memory'],
    [UserRoundCheck, m.noHelperTitle(), m.noHelperDescription(), 'battery'],
    [Feather, m.nativeTitle(), m.nativeDescription(), 'cpu'],
    [CodeXml, m.openSourceTitle(), m.openSourceDescription(), 'network'],
  ] as const
  return (
    <>
      <HeroSection />
      <div className={styles.container}>
        <section id="features" className={styles.section} aria-labelledby="features-title">
          <div className={styles.center}>
            <p className={styles.eyebrow}>{m.monitoring()}</p>
            <h2 id="features-title">{m.featuresTitle()}</h2>
            <p className={styles.lead}>{m.featuresLead()}</p>
          </div>
          <FeatureGrid />
        </section>
        <section id="battery" className={styles.battery} aria-labelledby="battery-title">
          <div>
            <p className={`${styles.eyebrow} ${styles.green}`}>{m.battery()}</p>
            <h2 id="battery-title">{m.batteryTitle()}</h2>
            <p className={styles.lead}>{m.batteryLead()}</p>
            <ul className={styles.checks}>
              {checks.map(([title, detail]) => (
                <li key={title}>
                  <Check size={22} aria-hidden="true" />
                  <div>
                    <strong>{title}</strong>
                    <span>{detail}</span>
                  </div>
                </li>
              ))}
            </ul>
            <p className={styles.note}>{m.batteryRequirement()}</p>
          </div>
          <div>
            <BatteryDemo />
            <p className={styles.example}>{m.exampleData()}</p>
          </div>
        </section>
        <section id="ai-limits" className={styles.ai} aria-labelledby="ai-title">
          <ProductImage view="ai" alt={m.screenshotAlt({ view: m.aiLimits() })} />
          <div>
            <Badge variant="outline">{m.optional()}</Badge>
            <h2 id="ai-title">{m.aiTitle()}</h2>
            <p className={styles.lead}>{m.aiLead()}</p>
            <div className={styles.tags}>
              {['Claude Code', 'Codex', 'Cursor', 'Grok'].map((tool) => (
                <Tag variant="secondary" key={tool}>
                  {tool}
                </Tag>
              ))}
            </div>
            <p className={styles.note}>{m.aiNote()}</p>
          </div>
        </section>
        <section className={styles.section} aria-labelledby="dashboard-title">
          <div className={styles.center}>
            <p className={`${styles.eyebrow} ${styles.purple}`}>{m.dashboard()}</p>
            <h2 id="dashboard-title">{m.dashboardTitle()}</h2>
            <p className={styles.lead}>{m.dashboardLead()}</p>
          </div>
          <DashboardSection />
        </section>
        <section className={styles.section} aria-labelledby="privacy-title">
          <div className={styles.center}>
            <h2 id="privacy-title">{m.privacyTitle()}</h2>
            <p className={styles.lead}>{m.privacyLead()}</p>
          </div>
          <div className={styles.principles}>
            {principles.map(([Icon, title, description, metric]) => (
              <Card key={title} className={styles.principle}>
                <span className={styles.tile} data-metric={metric}>
                  <Icon size={18} aria-hidden="true" />
                </span>
                <h3>{title}</h3>
                <p>{description}</p>
              </Card>
            ))}
          </div>
        </section>
        <section id="install" className={styles.section} aria-labelledby="install-title">
          <div className={styles.center}>
            <p className={`${styles.eyebrow} ${styles.blue}`}>{m.install()}</p>
            <h2 id="install-title">{m.installTitle()}</h2>
            <p className={styles.lead}>{m.installLead()}</p>
          </div>
          <ol className={styles.steps}>
            {[
              [m.installStep1(), m.installDetail1()],
              [m.installStep2(), m.installDetail2()],
              [m.installStep3(), m.installDetail3()],
            ].map(([title, detail], i) => (
              <li key={title}>
                <span>{i + 1}</span>
                <strong>{title}</strong>
                <p>{detail}</p>
              </li>
            ))}
          </ol>
          <InstallNotice />
        </section>
        <FaqSection />
        <section className={styles.cta} aria-labelledby="cta-title">
          <Card className={styles.ctaCard}>
            <img src="/app-icon.png" width="88" height="88" alt="" loading="lazy" />
            <h2 id="cta-title">{m.ctaTitle()}</h2>
            <p>{m.ctaLead()}</p>
            <DownloadActions />
          </Card>
        </section>
        <SiteFooter />
      </div>
    </>
  )
}
