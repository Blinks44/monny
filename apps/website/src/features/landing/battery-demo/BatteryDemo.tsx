import { Badge } from '@moduix/react/badge'
import { Card } from '@moduix/react/card'
import {
  Slider,
  SliderLabel,
  SliderValueText,
  SliderControl,
  SliderTrack,
  SliderRange,
  SliderThumb,
  SliderHiddenInput,
  SliderMarkerGroup,
  SliderMarker,
} from '@moduix/react/slider'
import {
  Switch,
  SwitchLabel,
  SwitchControl,
  SwitchThumb,
  SwitchHiddenInput,
} from '@moduix/react/switch'
import { Pause } from 'lucide-react'
import { useState } from 'react'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './BatteryDemo.module.css'

export function BatteryDemo() {
  const [limit, setLimit] = useState(80)
  return (
    <Card className={styles.card}>
      <div className={styles.source}>
        <span>{m.powerAdapter()}</span>
        <Badge className={styles.holding}>
          <Pause size={12} aria-hidden="true" />
          {limit === 100 ? m.limitOff() : limit > 80 ? m.charging() : m.holding()}
        </Badge>
      </div>
      <div className={styles.battery} aria-hidden="true">
        <div className={styles.level} style={{ width: '80%' }}>
          <span>80%</span>
        </div>
        <div className={styles.marker} style={{ left: `${limit}%` }} />
      </div>
      <p className={styles.facts}>{m.batteryFacts()}</p>
      <Slider
        className={styles.slider}
        min={80}
        max={100}
        step={5}
        value={[limit]}
        onValueChange={({ value }) => setLimit(value[0] ?? 80)}
      >
        <div className={styles.label}>
          <SliderLabel>{m.chargeLimit()}</SliderLabel>
          <SliderValueText>{limit}%</SliderValueText>
        </div>
        <SliderControl>
          <SliderTrack>
            <SliderRange />
          </SliderTrack>
          <SliderThumb index={0}>
            <SliderHiddenInput />
          </SliderThumb>
        </SliderControl>
        <SliderMarkerGroup>
          {[80, 85, 90, 95, 100].map((value) => (
            <SliderMarker value={value} key={value}>
              {value}
            </SliderMarker>
          ))}
        </SliderMarkerGroup>
      </Slider>
      <Switch defaultChecked className={styles.switch}>
        <SwitchLabel>
          {m.optimizedCharging()}
          <small>{m.managedMacOS()}</small>
        </SwitchLabel>
        <SwitchControl>
          <SwitchThumb />
        </SwitchControl>
        <SwitchHiddenInput />
      </Switch>
    </Card>
  )
}
