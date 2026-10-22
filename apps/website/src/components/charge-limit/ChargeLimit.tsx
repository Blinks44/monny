import { Slider, SliderControl, SliderLabel, SliderMarker, SliderMarkerGroup, SliderRange, SliderThumbs, SliderTrack } from '@moduix/react/slider'
import { Switch, SwitchControl, SwitchHiddenInput, SwitchLabel } from '@moduix/react/switch'
import { Zap } from 'lucide-react'
import { useState } from 'react'
import { formatNumber, formatPercent, formatUnit } from '~/lib/format'
import { m } from '~/paraglide/messages.js'
import { Chip } from '../chip/Chip'
import styles from './ChargeLimit.module.css'

const level = 80
const targets = [80, 85, 90, 95, 100]

/**
 * The app's Battery hero and its native charge-limit control, working with sample values: 100 % means
 * no limit, a lower target moves the dotted marker, and the status follows as macOS would report it.
 */
export function ChargeLimit() {
  const [limit, setLimit] = useState(80)
  const [optimized, setOptimized] = useState(false)
  const holding = limit < 100 && level >= limit
  return (
    <div className={styles.root}>
      <div className={styles.head}>
        <span>
          <Zap size={14} aria-hidden /> {m.battery_adapter()}
        </span>
        {holding ? <Chip tone="success">{m.battery_holding()}</Chip> : <Chip tone="info">{m.battery_charging()}</Chip>}
      </div>
      <div>
        <div className={styles.battery} role="img" aria-label={m.battery_level_label({ level: formatPercent(level) })}>
          <div className={styles.fill} style={{ width: `${level}%` }}>
            {formatPercent(level)}
          </div>
          {limit < 100 && (
            <div className={styles.marker} style={{ left: `calc(5px + (100% - 10px) * ${limit / 100})` }}>
              <span>{m.battery_limit_marker({ limit: formatPercent(limit) })}</span>
            </div>
          )}
        </div>
        <p className={styles.facts}>{m.battery_facts({ health: formatPercent(94), cycles: '213', temperature: formatUnit(31, 'celsius') })}</p>
      </div>
      <Slider
        className={styles.limit}
        min={80}
        max={100}
        step={5}
        value={[limit]}
        onValueChange={({ value }) => setLimit(value[0])}
      >
        <div className={styles.limitHead}>
          <SliderLabel>{m.battery_charge_limit()}</SliderLabel>
          <strong>{limit === 100 ? m.battery_no_limit() : formatPercent(limit)}</strong>
        </div>
        <SliderControl className={styles.slider}>
          <SliderTrack>
            <SliderRange />
          </SliderTrack>
          <SliderThumbs />
        </SliderControl>
        <SliderMarkerGroup>
          {targets.map((target) => (
            <SliderMarker key={target} value={target}>
              {formatNumber(target)}
            </SliderMarker>
          ))}
        </SliderMarkerGroup>
      </Slider>
      <Switch className={styles.switchRow} checked={optimized} onCheckedChange={({ checked }) => setOptimized(checked)}>
        <SwitchLabel>
          {m.battery_optimized()}
          <small>{m.battery_optimized_note()}</small>
        </SwitchLabel>
        <SwitchControl />
        <SwitchHiddenInput />
      </Switch>
    </div>
  )
}
