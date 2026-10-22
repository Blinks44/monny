import { AiToolCard, Chip, Reveal, Section, SectionHeading } from '~/components'
import { aiTools } from '~/lib/ai'
import { m } from '~/paraglide/messages.js'
import styles from './AiLimits.module.css'

export function AiLimits() {
  return (
    <Section id="ai">
      <div className={styles.heading}>
        <Chip tone="info" large>
          {m.ai_badge()}
        </Chip>
        <SectionHeading title={m.ai_title()} lead={m.ai_lead()} centered />
      </div>
      <div className={styles.grid}>
        {aiTools().map((tool, index) => (
          <Reveal key={tool.service} delay={(index % 2) * 0.08}>
            <AiToolCard tool={tool} />
          </Reveal>
        ))}
      </div>
      <p className={styles.note}>{m.ai_note()}</p>
    </Section>
  )
}
