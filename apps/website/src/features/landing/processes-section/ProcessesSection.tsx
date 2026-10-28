import { ChevronDown, ChevronRight, Search } from 'lucide-react'
import { useState } from 'react'
import { m } from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import {
  CardLabel,
  ChoiceChips,
  FeatureCard,
  FeatureSection,
  Note,
  SideCard,
} from '../feature-section'
import styles from './ProcessesSection.module.css'

type Mode = 'top' | 'port'

const apps = [
  { name: 'Safari', letter: 'S', color: '#3b82f6', cpu: 0.124, memory: 1.2, count: 4 },
  { name: 'Xcode', letter: 'X', color: '#2563eb', cpu: 0.098, memory: 3.1, count: 9 },
  { name: 'Figma', letter: 'F', color: '#e11d48', cpu: 0.031, memory: 0.64, count: 3 },
]
const topCpu = Math.max(...apps.map((app) => app.cpu))
const helpers = [
  ['Safari', 0.021],
  ['Safari Web Content', 0.064],
  ['Safari Web Content', 0.032],
  ['Safari Networking', 0.007],
] as const

export function ProcessesSection() {
  const [mode, setMode] = useState<Mode>('top')
  const locale = getLocale()
  const percent = (value: number) =>
    new Intl.NumberFormat(locale, { style: 'percent', minimumFractionDigits: 1 }).format(value)
  const memory = (gigabytes: number) =>
    gigabytes < 1
      ? new Intl.NumberFormat(locale, { style: 'unit', unit: 'megabyte' }).format(gigabytes * 1000)
      : new Intl.NumberFormat(locale, { style: 'unit', unit: 'gigabyte' }).format(gigabytes)
  return (
    <FeatureSection
      id="processes"
      eyebrow={m.processes()}
      metric="upload"
      title={m.processesTitle()}
      lead={m.processesLead()}
      extras={
        <SideCard>
          <CardLabel>{m.oneRowPerApp()}</CardLabel>
          <ul className={styles.helpers}>
            {helpers.map(([name, cpu], i) => (
              <li key={i}>
                <span>{name}</span>
                <span>{percent(cpu)}</span>
              </li>
            ))}
          </ul>
          <div className={styles.arrow} aria-hidden="true">
            ↓
          </div>
          <div className={`${styles.app} ${styles.summed}`}>
            <span className={styles.tile} style={{ background: '#3b82f6' }} aria-hidden="true">
              S
            </span>
            <span className={styles.name}>
              <strong>Safari</strong>
              <span>
                {memory(1.2)} · {m.processCount({ count: 4 })}
              </span>
            </span>
            <strong>{percent(0.124)}</strong>
          </div>
        </SideCard>
      }
    >
      <FeatureCard>
        <ChoiceChips
          label={m.processesExample()}
          options={[
            ['top', m.topApps()],
            ['port', m.portExample()],
          ]}
          value={mode}
          onValueChange={setMode}
        />
        <div className={styles.toolbar} aria-hidden="true">
          <span className={styles.search} data-active={mode === 'port' || undefined}>
            <Search size={14} />
            {mode === 'port' ? '3002' : m.searchPlaceholder()}
          </span>
          {mode === 'top' && (
            <span className={styles.sort}>
              {m.cpu()}
              <ChevronDown size={14} />
            </span>
          )}
        </div>
        {mode === 'top' ? (
          <>
            <div className={styles.attention}>
              <span className={styles.groupTitle}>{m.needsAttention()}</span>
              <div className={styles.app}>
                <span className={`${styles.tile} ${styles.terminal}`} aria-hidden="true">
                  &gt;_
                </span>
                <span className={styles.name}>
                  <strong>node</strong>
                  <span className={styles.busy}>
                    {m.busyFor({
                      value: new Intl.NumberFormat(locale, { style: 'percent' }).format(0.99),
                    })}
                  </span>
                </span>
                <span className={styles.button}>{m.quit()}</span>
              </div>
            </div>
            <ul className={styles.list}>
              {apps.map((app) => (
                <li key={app.name} className={styles.app}>
                  <span
                    className={styles.tile}
                    style={{ background: app.color }}
                    aria-hidden="true"
                  >
                    {app.letter}
                  </span>
                  <span className={styles.name}>
                    <strong>{app.name}</strong>
                    <span>
                      {memory(app.memory)} · {m.processCount({ count: app.count })}
                    </span>
                  </span>
                  <span className={styles.value}>
                    <strong>{percent(app.cpu)}</strong>
                    <i style={{ width: `${(app.cpu / topCpu) * 100}%` }} />
                  </span>
                </li>
              ))}
            </ul>
            <Note>{m.processesNote()}</Note>
          </>
        ) : (
          <>
            <span className={styles.groupTitle}>{m.listeningOn({ port: 3002 })}</span>
            <div className={`${styles.app} ${styles.result}`}>
              <span className={`${styles.tile} ${styles.terminal}`} aria-hidden="true">
                &gt;_
              </span>
              <span className={styles.name}>
                <strong>node</strong>
                <span>{m.pidPath({ pid: 48216, path: '~/dev/shop-web' })}</span>
              </span>
              <span className={styles.port}>
                <strong>:3002</strong>
                <span>TCP</span>
              </span>
              <ChevronRight size={14} aria-hidden="true" />
            </div>
            <span className={styles.groupTitle}>{m.processWithPid({ pid: 3002 })}</span>
            <div className={`${styles.app} ${styles.result}`}>
              <span className={`${styles.tile} ${styles.terminal}`} aria-hidden="true">
                V
              </span>
              <span className={styles.name}>
                <strong>Code Helper (Plugin)</strong>
                <span>{m.pidPath({ pid: 3002, path: 'Visual Studio Code' })}</span>
              </span>
              <ChevronRight size={14} aria-hidden="true" />
            </div>
            <p className={styles.hint}>{m.portHint()}</p>
            <Note>{m.portNote()}</Note>
          </>
        )}
      </FeatureCard>
    </FeatureSection>
  )
}
