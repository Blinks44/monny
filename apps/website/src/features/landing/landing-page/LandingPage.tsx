import claudeLogo from '@/assets/ai/claude.svg'
import codexLogo from '@/assets/ai/codex.svg'
import cursorLogo from '@/assets/ai/cursor.svg'
import grokLogo from '@/assets/ai/grok.svg'
import jetbrainsLogo from '@/assets/ai/jetbrains.svg'
import copilotLogo from '@/assets/ai/copilot.svg'
import clineLogo from '@/assets/ai/cline.svg'
import codebuffLogo from '@/assets/ai/codebuff.png'
import ampLogo from '@/assets/ai/amp.svg'
import augmentLogo from '@/assets/ai/augment.svg'
import nousLogo from '@/assets/ai/nous.svg'
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

const tools = [
  ['Claude Code', claudeLogo, 'claude'],
  ['Codex', codexLogo, 'codex'],
  ['Cursor', cursorLogo, 'cursor'],
  ['Grok', grokLogo, 'grok'],
  ['JetBrains AI', jetbrainsLogo, 'jetbrains'],
  ['GitHub Copilot', copilotLogo, 'copilot'],
  ['ClinePass', clineLogo, 'cline'],
  ['Codebuff', codebuffLogo, 'codebuff'],
  ['Amp', ampLogo, 'amp'],
  ['Augment', augmentLogo, 'augment'],
  ['Nous Portal', nousLogo, 'nous'],
]

function ToolTags({ tools }: { tools: string[][] }) {
  return (
    <div className={styles.tags}>
      {tools.map(([name, logo, brand]) => (
        <Tag variant="secondary" key={name}>
          <span className={styles.toolLogo} data-brand={brand}>
            <img src={logo} width="16" height="16" alt="" loading="lazy" />
          </span>
          {name}
        </Tag>
      ))}
    </div>
  )
}

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
            <h2 id="features-title" className={styles.heading}>
              {m.featuresTitle()}
            </h2>
            <p className={styles.lead}>{m.featuresLead()}</p>
          </div>
          <FeatureGrid />
        </section>
        <section id="battery" className={styles.battery} aria-labelledby="battery-title">
          <div>
            <p className={`${styles.eyebrow} ${styles.green}`}>{m.battery()}</p>
            <h2 id="battery-title" className={`${styles.heading} ${styles.batteryHeading}`}>
              {m.batteryTitle()}
            </h2>
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
          <ProductImage
            view="ai"
            alt={m.screenshotAlt({ view: m.aiLimits() })}
            sizes="(max-width: 700px) 100vw, (max-width: 1240px) 63vw, 764px"
          />
          <div>
            <Badge variant="outline">{m.optional()}</Badge>
            <h2 id="ai-title" className={`${styles.heading} ${styles.aiHeading}`}>
              {m.aiTitle()}
            </h2>
            <p className={styles.lead}>{m.aiLead()}</p>
            <ToolTags tools={tools} />
            <div className={styles.selection}>
              <h3>{m.aiSelectionTitle()}</h3>
              <p>{m.aiSelectionReason()}</p>
            </div>
            <p className={styles.note}>{m.aiNote()}</p>
          </div>
        </section>
        <section className={styles.section} aria-labelledby="dashboard-title">
          <div className={styles.center}>
            <p className={`${styles.eyebrow} ${styles.purple}`}>{m.dashboard()}</p>
            <h2 id="dashboard-title" className={styles.heading}>
              {m.dashboardTitle()}
            </h2>
            <p className={styles.lead}>{m.dashboardLead()}</p>
          </div>
          <DashboardSection />
        </section>
        <section className={styles.section} aria-labelledby="privacy-title">
          <div className={styles.center}>
            <h2 id="privacy-title" className={styles.heading}>
              {m.privacyTitle()}
            </h2>
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
            <h2 id="install-title" className={styles.heading}>
              {m.installTitle()}
            </h2>
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
            <h2 id="cta-title" className={`${styles.heading} ${styles.ctaHeading}`}>
              {m.ctaTitle()}
            </h2>
            <p>{m.ctaLead()}</p>
            <DownloadActions />
          </Card>
        </section>
        <SiteFooter />
      </div>
    </>
  )
}
