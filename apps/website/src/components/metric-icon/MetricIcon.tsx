import { clsx } from 'clsx'
import type { LucideIcon } from 'lucide-react'
import { type Metric, tint } from '~/lib/metrics'
import styles from './MetricIcon.module.css'

export function MetricIcon({ icon: Icon, metric, size = 'md' }: { icon: LucideIcon; metric: Metric; size?: 'md' | 'lg' }) {
  return (
    <span className={clsx(styles.icon, size === 'lg' && styles.large)} style={tint(metric)}>
      <Icon size={size === 'lg' ? 22 : 14} strokeWidth={2.2} aria-hidden />
    </span>
  )
}
