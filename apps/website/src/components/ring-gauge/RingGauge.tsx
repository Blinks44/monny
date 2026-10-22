import { ProgressCircular, ProgressCircularRing, ProgressCircularValueText } from '@moduix/react/progress-circular'
import { type Metric, tint } from '~/lib/metrics'
import { getLocale } from '~/paraglide/runtime.js'
import styles from './RingGauge.module.css'

export function RingGauge({ value, metric, label, unit }: { value: number; metric: Metric; label: string; unit: string }) {
  return (
    <ProgressCircular value={value} locale={getLocale()} className={styles.gauge} style={tint(metric)}>
      <ProgressCircularRing aria-label={label} />
      <span className={styles.label}>
        <ProgressCircularValueText className={styles.value} />
        <small>{unit}</small>
      </span>
    </ProgressCircular>
  )
}
