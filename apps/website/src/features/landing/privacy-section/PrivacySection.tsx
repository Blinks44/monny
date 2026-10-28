import { m } from '@/integrations/i18n/paraglide/messages'
import { CardLabel, FeatureCard, FeatureSection } from '../feature-section'
import styles from './PrivacySection.module.css'

export function PrivacySection() {
  const rows = [
    [m.dataReadings(), m.destMac(), true],
    [m.dataUpdates(), m.destGithub(), false],
    [m.dataAI(), m.destTools(), false],
    [m.dataLimit(), m.destMacOS(), true],
  ] as const
  return (
    <FeatureSection
      id="privacy"
      eyebrow={m.privacy()}
      metric="memory"
      title={m.privacyTitle()}
      lead={m.privacyLead()}
    >
      <FeatureCard>
        <CardLabel>{m.whereDataGoes()}</CardLabel>
        <dl className={styles.table}>
          {rows.map(([data, destination, local]) => (
            <div key={data}>
              <dt>{data}</dt>
              <dd data-local={local || undefined}>{destination}</dd>
            </div>
          ))}
        </dl>
      </FeatureCard>
    </FeatureSection>
  )
}
