import claudeLogo from '@/assets/ai/claude.svg'
import codexLogo from '@/assets/ai/codex.svg'
import cursorLogo from '@/assets/ai/cursor.svg'
import grokLogo from '@/assets/ai/grok.svg'
import jetbrainsLogo from '@/assets/ai/jetbrains.svg'
import copilotLogo from '@/assets/ai/copilot.svg'
import clineLogo from '@/assets/ai/cline.svg'
import codebuffLogo from '@/assets/ai/codebuff.png'
import ampLogo from '@/assets/ai/amp.svg'
import augmentLogo from '@/assets/ai/augment.svg'
import nousLogo from '@/assets/ai/nous.svg'
import { Badge } from '@moduix/react/badge'
import { Tag } from '@moduix/react/tag'
import { m } from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { CardLabel, FeatureCard, FeatureSection, Note } from '../feature-section'
import styles from './AISection.module.css'

type Tool = readonly [name: string, logo: string, brand: string]

const sources: readonly (readonly [() => string, readonly Tool[]])[] = [
  [
    m.sourceApi,
    [
      ['Claude Code', claudeLogo, 'claude'],
      ['Codex', codexLogo, 'codex'],
      ['Cursor', cursorLogo, 'cursor'],
      ['Grok', grokLogo, 'grok'],
      ['GitHub Copilot', copilotLogo, 'copilot'],
      ['ClinePass', clineLogo, 'cline'],
      ['Codebuff', codebuffLogo, 'codebuff'],
      ['Nous Portal', nousLogo, 'nous'],
    ],
  ],
  [
    m.sourceCommand,
    [
      ['Amp', ampLogo, 'amp'],
      ['Augment', augmentLogo, 'augment'],
    ],
  ],
  [m.sourceLocal, [['JetBrains AI', jetbrainsLogo, 'jetbrains']]],
]

/** Example window: quota left and time left in the window, both 0–1. */
function Window({ label, left, time }: { label: string; left: number; time: number }) {
  return (
    <div className={styles.window}>
      <span>{label}</span>
      <strong>{m.remaining({ value: Math.round(left * 100) })}</strong>
      <div className={styles.bar} aria-hidden="true">
        <i style={{ width: `${left * 100}%` }} />
        <b style={{ left: `${time * 100}%` }} />
      </div>
    </div>
  )
}

export function AISection() {
  const locale = getLocale()
  const time = new Intl.DateTimeFormat(locale, {
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  })
  const day = new Intl.DateTimeFormat(locale, { weekday: 'short' })
  const at = (date: Date) => m.dayTime({ day: day.format(date), time: time.format(date) })
  const today = time.format(new Date(2026, 10, 2, 13, 2))
  const monday = at(new Date(2026, 10, 2, 9, 0))
  const tuesday = at(new Date(2026, 10, 3, 18, 40))
  const states = [
    [m.onTrack(), m.leftResets({ value: 66, time: today }), 0.66, null],
    [m.underTen(), m.leftResets({ value: 8, time: tuesday }), 0.08, 'low'],
    [m.usedUp(), m.availableAgain({ time: tuesday }), 0, 'reached'],
    [m.olderThan(), m.checkedAgo({ value: 22 }), 0.52, 'stale'],
  ] as const
  return (
    <FeatureSection
      id="ai-limits"
      eyebrow={<Badge variant="outline">{m.optional()}</Badge>}
      title={m.aiTitle()}
      lead={m.aiLead()}
      visualFirst
      extras={
        <div className={styles.sources}>
          {sources.map(([label, tools]) => (
            <div key={label()}>
              <p>{label()}</p>
              <div className={styles.tags}>
                {tools.map(([name, logo, brand]) => (
                  <Tag variant="secondary" key={name}>
                    <span className={styles.toolLogo} data-brand={brand}>
                      <img src={logo} width="16" height="16" alt="" loading="lazy" />
                    </span>
                    {name}
                  </Tag>
                ))}
              </div>
            </div>
          ))}
          <p className={styles.note}>{m.aiNote()}</p>
        </div>
      }
    >
      <FeatureCard>
        <div className={styles.tool}>
          <span className={styles.toolLogo} data-brand="claude">
            <img src={claudeLogo} width="18" height="18" alt="" loading="lazy" />
          </span>
          <span>
            <strong>Claude Code</strong>
            <span>{m.aiPlan()}</span>
          </span>
        </div>
        <Window label={m.fiveHourResets({ time: today })} left={0.66} time={0.48} />
        <Window label={m.weeklyResets({ time: monday })} left={0.39} time={0.55} />
        <Note>{m.paceNote()}</Note>
        <div className={styles.states}>
          <CardLabel>{m.windowStates()}</CardLabel>
          <ul>
            {states.map(([title, detail, left, state]) => (
              <li key={title} data-state={state ?? undefined}>
                <span>
                  <strong>{title}</strong>
                  <span>{detail}</span>
                </span>
                {state === 'low' && <em>{m.runningLow()}</em>}
                {state === 'reached' && <em>{m.limitReached()}</em>}
                <i aria-hidden="true">
                  <b style={{ width: `${left * 100}%` }} />
                </i>
              </li>
            ))}
          </ul>
        </div>
      </FeatureCard>
    </FeatureSection>
  )
}
