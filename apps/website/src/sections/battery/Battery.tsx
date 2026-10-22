import { CircleCheck } from 'lucide-react'
import { ChargeLimit, Reveal, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Battery.module.css'

export function Battery() {
  const points = [
    { title: m.battery_point_native_title(), text: m.battery_point_native_text() },
    { title: m.battery_point_persist_title(), text: m.battery_point_persist_text() },
    { title: m.battery_point_safe_title(), text: m.battery_point_safe_text() },
  ]
  return (
    <Section id="battery">
      <div className={styles.layout}>
        <div>
          <SectionHeading title={m.battery_title()} lead={m.battery_lead()} />
          <Reveal>
            <ul className={styles.points}>
              {points.map((point) => (
                <li key={point.title}>
                  <CircleCheck size={20} aria-hidden />
                  <strong>{point.title}</strong>
                  <p>{point.text}</p>
                </li>
              ))}
            </ul>
            <p className={styles.note}>{m.battery_requirement()}</p>
          </Reveal>
        </div>
        <Reveal className={styles.card} delay={0.1}>
          <ChargeLimit />
        </Reveal>
      </div>
    </Section>
  )
}
