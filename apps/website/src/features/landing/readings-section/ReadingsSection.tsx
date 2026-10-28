import { m } from '@/integrations/i18n/paraglide/messages'
import { CardLabel, FeatureCard, FeatureSection, Note, SideCard } from '../feature-section'
import styles from './ReadingsSection.module.css'

/** Seconds of each read within the drawn 30-second window. */
const reads = (every: number) => Array.from({ length: 30 / every + 1 }, (_, i) => i * every)

function Timeline({ title, detail, every }: { title: string; detail: string; every: number }) {
  return (
    <div className={styles.row}>
      <strong>{title}</strong>
      <span>{detail}</span>
      <div className={styles.track} data-every={every} aria-hidden="true">
        {reads(every).map((second) => (
          <i key={second} style={{ left: `${(second / 30) * 100}%` }} />
        ))}
      </div>
    </div>
  )
}

export function ReadingsSection() {
  const states = [
    ['nominal', m.nominal()],
    ['fair', m.fair()],
    ['serious', m.serious()],
    ['critical', m.critical()],
  ]
  const sensors = [
    ['CPU', '52°'],
    ['GPU', '47°'],
    ['SSD', '38°'],
    [m.fan(), m.unavailableValue()],
  ]
  return (
    <FeatureSection
      id="readings"
      eyebrow={m.readings()}
      metric="cpu"
      title={m.readingsTitle()}
      lead={m.readingsLead()}
      visualFirst
      extras={
        <SideCard>
          <CardLabel>{m.unavailableLabel()}</CardLabel>
          <ul className={styles.sensors}>
            {sensors.map(([name, value], i) => (
              <li key={name} data-unavailable={i === sensors.length - 1 || undefined}>
                <span>{name}</span>
                <strong>{value}</strong>
              </li>
            ))}
          </ul>
          <Note>{m.sensorsNote()}</Note>
        </SideCard>
      }
    >
      <FeatureCard>
        <CardLabel>{m.samplingLabel()}</CardLabel>
        <Timeline title={m.popoverOpen()} detail={m.popoverOpenDetail()} every={2} />
        <Timeline title={m.allClosed()} detail={m.allClosedDetail()} every={10} />
        <div className={styles.axis} aria-hidden="true">
          {[0, 10, 20, 30].map((second) => (
            <span key={second}>{m.seconds({ value: second })}</span>
          ))}
        </div>
        <div className={styles.thermal}>
          <strong>{m.thermalTitle()}</strong>
          <span>{m.thermalDetail()}</span>
          <ul>
            {states.map(([state, label]) => (
              <li key={state} data-state={state}>
                {label}
              </li>
            ))}
          </ul>
        </div>
        <Note>{m.samplingNote()}</Note>
      </FeatureCard>
    </FeatureSection>
  )
}
