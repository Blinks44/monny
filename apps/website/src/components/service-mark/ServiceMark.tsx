import { clsx } from 'clsx'
import styles from './ServiceMark.module.css'

export type Service = 'claude' | 'codex' | 'cursor' | 'grok'

/** The marks only identify the services; they are trademarks of their owners. */
export function ServiceMark({ service }: { service: Service }) {
  return (
    <span className={clsx(styles.mark, styles[service])}>
      <img src={`/ai/${service}.svg`} alt="" width={18} height={18} />
    </span>
  )
}
