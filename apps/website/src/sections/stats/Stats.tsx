import { Card } from '@moduix/react/card'
import { Feather, History, Languages, type LucideIcon, ShieldCheck } from 'lucide-react'
import { MetricIcon, Reveal, Section } from '~/components'
import type { Metric } from '~/lib/metrics'
import { m } from '~/paraglide/messages.js'
import styles from './Stats.module.css'

export function Stats() {
  return (
    <Section flush>
      <Reveal>
        <Card asChild className={styles.stats}>
          <dl>
            <Stat icon={Feather} metric="cpu" value={m.stat_cost_value()} label={m.stat_cost_label()} />
            <Stat icon={ShieldCheck} metric="memory" value={m.stat_data_value()} label={m.stat_data_label()} />
            <Stat icon={History} metric="network" value={m.stat_history_value()} label={m.stat_history_label()} />
            <Stat icon={Languages} metric="battery" value={m.stat_languages_value()} label={m.stat_languages_label()} />
          </dl>
        </Card>
      </Reveal>
    </Section>
  )
}

function Stat({ icon, metric, value, label }: { icon: LucideIcon; metric: Metric; value: string; label: string }) {
  return (
    <div className={styles.stat}>
      <MetricIcon icon={icon} metric={metric} />
      <dt className={styles.label}>{label}</dt>
      <dd className={styles.value}>{value}</dd>
    </div>
  )
}
