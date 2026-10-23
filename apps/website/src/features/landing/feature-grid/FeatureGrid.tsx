import { Card } from '@moduix/react/card'
import {
  ProgressLinear,
  ProgressLinearRange,
  ProgressLinearTrack,
} from '@moduix/react/progress-linear'
import type { CSSProperties } from 'react'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './FeatureGrid.module.css'

export function FeatureGrid() {
  const features = [
    {
      key: 'cpu',
      label: m.cpu(),
      title: m.cpuTitle(),
      description: m.cpuDescription(),
      sample: '34%',
    },
    {
      key: 'memory',
      label: m.memory(),
      title: m.memory(),
      description: m.memoryDescription(),
      sample: '11.2 GB',
    },
    {
      key: 'disk',
      label: m.disk(),
      title: m.disk(),
      description: m.diskDescription(),
      sample: '412 GB',
    },
    {
      key: 'network',
      label: m.network(),
      title: m.network(),
      description: m.networkDescription(),
      sample: '2.4 MB/s',
    },
    {
      key: 'heat',
      label: m.sensors(),
      title: m.sensorsTitle(),
      description: m.sensorsDescription(),
      sample: '52°',
    },
    {
      key: 'upload',
      label: m.processes(),
      title: m.processesTitle(),
      description: m.processesDescription(),
      sample: 'Xcode',
    },
  ]
  return (
    <div className={styles.grid}>
      {features.map((feature) => (
        <Card
          key={feature.key}
          className={styles.card}
          style={{ '--metric': `var(--monny-metric-${feature.key})` } as CSSProperties}
        >
          <div className={styles.label}>
            {feature.label}
            <span className={styles.mobileSample} aria-hidden="true">
              {feature.sample}
            </span>
          </div>
          <h3>{feature.title}</h3>
          <p>{feature.description}</p>
          <div className={styles.visual} aria-hidden="true">
            {feature.key === 'cpu' && (
              <div className={styles.cores}>
                {[72, 55, 46, 62, 35, 51, 29, 25, 40, 20, 29, 22].map((height, i) => (
                  <span key={i}>
                    <i style={{ height: `${height}%` }} />
                  </span>
                ))}
              </div>
            )}
            {(feature.key === 'memory' || feature.key === 'disk') && (
              <>
                <span>{feature.key === 'memory' ? m.memoryValue() : m.freeSpace()}</span>
                <ProgressLinear value={feature.key === 'memory' ? 62 : 59}>
                  <ProgressLinearTrack>
                    <ProgressLinearRange />
                  </ProgressLinearTrack>
                </ProgressLinear>
              </>
            )}
            {feature.key === 'network' && (
              <>
                <strong>↓ 2.4 MB/s</strong>
                <small>↑ 320 KB/s</small>
                <div className={styles.network}>
                  {[
                    7, 12, 9, 16, 13, 21, 14, 10, 19, 12, 15, 8, 13, 18, 12, 9, 14, 20, 16, 10, 12,
                    14,
                  ].map((height, i) => (
                    <i key={i} style={{ height }} />
                  ))}
                </div>
              </>
            )}
            {feature.key === 'heat' && (
              <div className={styles.sensors}>
                {[
                  ['CPU', '52°'],
                  ['GPU', '47°'],
                  ['SSD', '38°'],
                  [m.fan(), '1 840 rpm'],
                ].map(([label, value]) => (
                  <span key={label}>
                    <small>{label}</small>
                    <strong>{value}</strong>
                  </span>
                ))}
              </div>
            )}
            {feature.key === 'upload' && (
              <div className={styles.processes}>
                {[
                  ['Xcode', 100, '14.2%'],
                  ['Safari', 43, '6.1%'],
                  ['Figma', 27, '3.8%'],
                ].map(([name, value, label]) => (
                  <div key={name}>
                    <span>{name}</span>
                    <ProgressLinear value={Number(value)}>
                      <ProgressLinearTrack>
                        <ProgressLinearRange />
                      </ProgressLinearTrack>
                    </ProgressLinear>
                    <span>{label}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </Card>
      ))}
    </div>
  )
}
