import { BatteryFull, Cpu, Thermometer, Wifi } from 'lucide-react'
import { useState } from 'react'
import { m } from '@/integrations/i18n/paraglide/messages'
import {
  CardLabel,
  FeatureCard,
  FeatureSection,
  Note,
  ResultRows,
  SideCard,
  ToggleChips,
} from '../feature-section'
import styles from './MenuBarSection.module.css'

type Reading = 'cpu' | 'temperature' | 'battery'

export function MenuBarSection() {
  const [readings, setReadings] = useState<Reading[]>(['cpu', 'temperature', 'battery'])
  const shown = (reading: Reading) => readings.includes(reading)
  return (
    <FeatureSection
      id="menu-bar"
      eyebrow={m.menuBar()}
      metric="network"
      title={m.menuBarTitle()}
      lead={m.menuBarLead()}
      extras={
        <SideCard>
          <CardLabel>{m.clicksAndKeys()}</CardLabel>
          <ResultRows
            rows={[
              [m.click(), m.opensPopover()],
              [m.rightClick(), m.opensMenu()],
              ['⌥⌘M', m.opensDashboard()],
            ]}
          />
        </SideCard>
      }
    >
      <FeatureCard>
        <CardLabel>{m.showInMenuBar()}</CardLabel>
        <ToggleChips
          label={m.showInMenuBar()}
          options={[
            ['cpu', m.cpuLoad()],
            ['temperature', m.temperature()],
            ['battery', m.batteryLevel()],
          ]}
          value={readings}
          onValueChange={setReadings}
        />
        <div className={styles.desktop} aria-hidden="true">
          <div className={styles.bar}>
            <span className={styles.titles}>Finder&ensp;File&ensp;Edit&ensp;View</span>
            <span className={styles.status}>
              <span className={styles.icon}>
                <i />
                <i />
                <i />
                <div className={styles.menu}>
                  <span className={styles.selected}>
                    {m.menuOpenDashboard()}
                    <kbd>⌥⌘M</kbd>
                  </span>
                  <span>
                    {m.menuSettings()}
                    <kbd>⌘,</kbd>
                  </span>
                  <hr />
                  <span>{m.menuTurnOffLimit()}</span>
                  <hr />
                  <span>{m.menuCheckUpdates()}</span>
                  <span>
                    {m.menuQuit()}
                    <kbd>⌘Q</kbd>
                  </span>
                </div>
              </span>
              {shown('cpu') && (
                <span>
                  <Cpu size={13} />
                  23%
                </span>
              )}
              {shown('temperature') && (
                <span>
                  <Thermometer size={13} />
                  52°
                </span>
              )}
              {shown('battery') && (
                <span>
                  <BatteryFull size={15} />
                  80%
                </span>
              )}
              <Wifi size={14} />
              <span>10:24</span>
            </span>
          </div>
        </div>
        <Note>{m.menuBarHint()}</Note>
      </FeatureCard>
    </FeatureSection>
  )
}
