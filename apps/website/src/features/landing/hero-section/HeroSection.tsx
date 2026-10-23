import { Badge, BadgeDot } from '@moduix/react/badge'
import { Card } from '@moduix/react/card'
import {
  ProgressLinear,
  ProgressLinearTrack,
  ProgressLinearRange,
} from '@moduix/react/progress-linear'
import { DownloadActions } from '@/components/download-actions'
import { ProductImage } from '@/components/product-image'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import { InstallNotice } from '../install-notice'
import styles from './HeroSection.module.css'

export function HeroSection() {
  return (
    <section className={styles.hero} aria-labelledby="hero-title">
      <div className={styles.intro}>
        <Badge variant="outline" className={styles.badge}>
          <BadgeDot />
          {m.freeBadge()}
        </Badge>
        <h1 id="hero-title">
          {m.heroTitle()}
          <span>{m.heroAccent()}</span>
        </h1>
        <p className={styles.lead}>{m.heroLead()}</p>
        <DownloadActions mobileCopy />
        <p className={styles.meta}>{m.compatibility()}</p>
        {!site.downloadUrl && <p className={styles.release}>{m.releasePending()}</p>}
        <InstallNotice compact />
      </div>
      <div className={styles.stage}>
        <ProductImage
          view="overview"
          alt={m.screenshotAlt({ view: m.overview() })}
          className={styles.overview}
        />
        <div className={styles.popover}>
          <ProductImage view="popover" alt={m.popoverAlt()} eager />
        </div>
        <Card className={styles.aiCard}>
          <div className={styles.aiHeader}>
            <span>{m.aiLimits()}</span>
            <small>{m.updated()}</small>
          </div>
          {(
            [
              ['Claude Code', 66],
              ['Codex', 88],
              ['Cursor', 62],
            ] as const
          ).map(([tool, value]) => (
            <div className={styles.aiRow} key={tool}>
              <div>
                <strong>{tool}</strong>
                <small>{tool === 'Cursor' ? m.monthlyLimit() : m.fiveHour()}</small>
              </div>
              <div>
                <span>{m.remaining({ value })}</span>
                <ProgressLinear value={value} aria-label={tool}>
                  <ProgressLinearTrack>
                    <ProgressLinearRange />
                  </ProgressLinearTrack>
                </ProgressLinear>
              </div>
            </div>
          ))}
        </Card>
      </div>
      <p className={styles.example}>{m.exampleData()}</p>
    </section>
  )
}
