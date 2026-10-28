import { Card } from '@moduix/react/card'
import { DownloadActions } from '@/components/download-actions'
import { m } from '@/integrations/i18n/paraglide/messages'
import { HeroSection } from '../hero-section'
import { DashboardSection } from '../dashboard-section'
import { MenuBarSection } from '../menu-bar-section'
import { ReadingsSection } from '../readings-section'
import { ProcessesSection } from '../processes-section'
import { BatterySection } from '../battery-section'
import { NotificationsSection } from '../notifications-section'
import { AISection } from '../ai-section'
import { PrivacySection } from '../privacy-section'
import { InstallNotice } from '../install-notice'
import { FaqSection } from '../faq-section'
import { SiteFooter } from '../site-footer'
import styles from './LandingPage.module.css'

export function LandingPage() {
  return (
    <>
      <HeroSection />
      <div className={styles.container}>
        <section className={styles.dashboard} aria-labelledby="dashboard-title">
          <div className={styles.center}>
            <p className={`${styles.eyebrow} ${styles.purple}`}>{m.dashboard()}</p>
            <h2 id="dashboard-title" className={styles.heading}>
              {m.dashboardTitle()}
            </h2>
            <p className={styles.lead}>{m.dashboardLead()}</p>
          </div>
          <DashboardSection />
        </section>
        <MenuBarSection />
        <ReadingsSection />
        <ProcessesSection />
        <BatterySection />
        <NotificationsSection />
        <AISection />
        <PrivacySection />
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
