import { clsx } from 'clsx'
import type { CSSProperties } from 'react'
import { formatPercent } from '~/lib/format'
import { m } from '~/paraglide/messages.js'
import { Chip } from '../chip/Chip'
import { Meter } from '../meter/Meter'
import styles from './QuotaBar.module.css'

/** One limit window: quota left in the service's color, the pace mark and the next reset. */
export function QuotaBar(props: { title: string; left: number; pace: number; reset: string; color: string }) {
  // Under 10 % left a window is running low, whatever the pace (SPEC §3).
  const low = props.left < 10
  return (
    <div className={clsx(styles.row, low && styles.low)} style={{ '--tint': props.color } as CSSProperties}>
      <div className={styles.head}>
        <span className={styles.title}>
          {props.title}
          {low && <Chip tone="warning">{m.ai_running_low()}</Chip>}
        </span>
        <strong>{m.ai_left({ value: formatPercent(props.left) })}</strong>
      </div>
      <Meter value={props.left} label={props.title} className={styles.bar}>
        <span className={styles.pace} style={{ left: `${props.pace}%` }} />
      </Meter>
      <span className={styles.reset}>{props.reset}</span>
    </div>
  )
}
