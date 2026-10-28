import { useState } from 'react'
import { m } from '@/integrations/i18n/paraglide/messages'
import { BatteryDemo } from '../battery-demo'
import {
  CardLabel,
  ChoiceChips,
  FeatureCard,
  FeatureSection,
  Note,
  SideCard,
} from '../feature-section'
import styles from './BatterySection.module.css'

type Source = 'charging' | 'battery'

/** Example adapter split: what the Mac uses and what goes into the battery, out of 96 W. */
const adapter = 96
const mac = 17
const intoBattery = 12

export function BatterySection() {
  const [source, setSource] = useState<Source>('charging')
  return (
    <FeatureSection
      id="battery"
      eyebrow={m.battery()}
      metric="battery"
      title={m.batteryTitle()}
      lead={m.batteryLead()}
      visualFirst
      extras={
        <>
          <SideCard>
            <CardLabel>{m.limitKept()}</CardLabel>
            <ul className={styles.kept}>
              {[m.youQuit(), m.macSleeps(), m.macRestarts()].map((event) => (
                <li key={event}>
                  {event}
                  <span>{m.limitMarker({ value: 80 })}</span>
                </li>
              ))}
            </ul>
            <Note>{m.limitKeptNote()}</Note>
          </SideCard>
          <p className={styles.requirement}>{m.batteryRequirement()}</p>
        </>
      }
    >
      <BatteryDemo />
      <FeatureCard>
        <ChoiceChips
          label={m.powerExample()}
          options={[
            ['charging', m.charging()],
            ['battery', m.onBattery()],
          ]}
          value={source}
          onValueChange={setSource}
        />
        {source === 'charging' ? (
          <>
            <div className={styles.power}>
              <strong>{m.watts({ value: mac + intoBattery })}</strong>
              <span>{m.inUse()}</span>
              <span className={styles.right}>{m.adapterWatts({ value: adapter })}</span>
            </div>
            <div className={styles.split} aria-hidden="true">
              <i style={{ width: `${(mac / adapter) * 100}%` }} />
              <i style={{ width: `${(intoBattery / adapter) * 100}%` }} />
            </div>
            <ul className={styles.legend}>
              <li>{m.macShare({ value: mac })}</li>
              <li>{m.batteryShare({ value: intoBattery })}</li>
            </ul>
          </>
        ) : (
          <div className={styles.power}>
            <strong>{m.watts({ value: 12 })}</strong>
            <span>{m.fromBattery()}</span>
            <span className={styles.right}>{m.timeLeft()}</span>
          </div>
        )}
        <Note>{m.powerNote()}</Note>
      </FeatureCard>
    </FeatureSection>
  )
}
