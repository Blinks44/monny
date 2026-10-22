import { Card } from '@moduix/react/card'
import type { AiTool } from '~/lib/ai'
import { m } from '~/paraglide/messages.js'
import { QuotaBar } from '../quota-bar/QuotaBar'
import { ServiceMark } from '../service-mark/ServiceMark'
import styles from './AiToolCard.module.css'

/** One AI tool as in the app's AI tab: its mark, plan, last reading and limit windows. */
export function AiToolCard({ tool }: { tool: AiTool }) {
  return (
    <Card className={styles.card}>
      <div className={styles.head}>
        <ServiceMark service={tool.service} />
        <div>
          <strong>{tool.name}</strong>
          <small>{tool.plan}</small>
        </div>
        <span className={styles.ago}>{m.ai_ago({ minutes: tool.ago })}</span>
      </div>
      {tool.limits.map((limit) => (
        <QuotaBar key={limit.title} {...limit} color={tool.color} />
      ))}
    </Card>
  )
}
