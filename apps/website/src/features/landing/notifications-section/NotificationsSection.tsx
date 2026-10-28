import { Check } from 'lucide-react'
import { m } from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { CardLabel, FeatureCard, FeatureSection, Note, SideCard } from '../feature-section'
import styles from './NotificationsSection.module.css'

/** Example CPU of one core over six minutes, drawn in a 576-wide box. */
const line =
  'M0 160 L24 156 L48 170 L72 150 L96 140 L110 40 L140 26 L180 34 L220 22 L260 30 L300 18 L340 28 L380 20 L420 32 L460 24 L500 30 L540 20 L576 26'

export function NotificationsSection() {
  const percent = new Intl.NumberFormat(getLocale(), { style: 'percent' }).format(0.8)
  const alerts = [
    [m.notifyChargeLimit(), true],
    [m.notifyHot(), true],
    [m.notifyBusyApp(), false],
    [m.notifyLowBattery(), false],
    [m.notifyMemory(), false],
    [m.notifyAI(), false],
  ] as const
  return (
    <FeatureSection
      id="notifications"
      eyebrow={m.notifications()}
      metric="disk"
      title={m.notificationsTitle()}
      lead={m.notificationsLead()}
      extras={
        <SideCard>
          <CardLabel>{m.notificationSettings()}</CardLabel>
          <ul className={styles.settings}>
            {alerts.map(([title, on]) => (
              <li key={title} data-on={on || undefined}>
                <span className={styles.box} aria-hidden="true">
                  {on && <Check size={13} strokeWidth={3} />}
                </span>
                {title}
              </li>
            ))}
          </ul>
          <Note>{m.notificationsNote()}</Note>
        </SideCard>
      }
    >
      <FeatureCard>
        <CardLabel>{m.busyChartLabel()}</CardLabel>
        <div className={styles.chart} aria-hidden="true">
          <span className={styles.window}>
            <small>{m.windowLabel()}</small>
          </span>
          <span className={styles.threshold}>
            <small>{m.thresholdLabel({ value: percent })}</small>
          </span>
          <svg viewBox="0 18 576 152" preserveAspectRatio="none">
            <path d={line} vectorEffect="non-scaling-stroke" />
          </svg>
        </div>
        <div className={styles.axis} aria-hidden="true">
          <span>{m.minutesAgo({ value: 6 })}</span>
          <span>{m.now()}</span>
        </div>
        <div className={styles.banner}>
          <img src="/app-icon.png" width="38" height="38" alt="" loading="lazy" />
          <div>
            <strong>{m.busyTitle({ name: 'Xcode' })}</strong>
            <span>{m.busyBody({ value: percent })}</span>
          </div>
        </div>
        <p className={styles.sent}>{m.sentOnce()}</p>
      </FeatureCard>
    </FeatureSection>
  )
}
