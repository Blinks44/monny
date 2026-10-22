import { Card, CardDescription, CardHeader, CardTitle } from '@moduix/react/card'
import type { LucideIcon } from 'lucide-react'
import type { Metric } from '~/lib/metrics'
import { MetricIcon } from '../metric-icon/MetricIcon'
import { Reveal } from '../reveal/Reveal'
import styles from './FeatureCard.module.css'

/** A feature as a tile in its metric's color, a title and a short text. */
export function FeatureCard(props: { icon: LucideIcon; metric: Metric; title: string; text: string; className?: string; delay?: number }) {
  return (
    <Reveal className={props.className} delay={props.delay}>
      <Card className={styles.card}>
        <CardHeader className={styles.header}>
          <MetricIcon icon={props.icon} metric={props.metric} size="lg" />
          <CardTitle asChild>
            <h3>{props.title}</h3>
          </CardTitle>
          <CardDescription>{props.text}</CardDescription>
        </CardHeader>
      </Card>
    </Reveal>
  )
}
