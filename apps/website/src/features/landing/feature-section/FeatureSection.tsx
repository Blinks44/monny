import { Card } from '@moduix/react/card'
import { ToggleGroup, ToggleGroupItem } from '@moduix/react/toggle-group'
import type { ComponentProps, CSSProperties, ReactNode } from 'react'
import styles from './FeatureSection.module.css'

export type Metric = 'cpu' | 'memory' | 'disk' | 'network' | 'upload' | 'battery'

/** A product section: text with optional extras on one side, the illustration on the other. */
export function FeatureSection({
  id,
  eyebrow,
  metric,
  title,
  lead,
  extras,
  visualFirst = false,
  children,
}: {
  id: string
  eyebrow: ReactNode
  metric?: Metric
  title: string
  lead: string
  extras?: ReactNode
  visualFirst?: boolean
  children: ReactNode
}) {
  return (
    <section
      id={id}
      className={visualFirst ? `${styles.section} ${styles.visualFirst}` : styles.section}
      aria-labelledby={`${id}-title`}
      style={
        metric ? ({ '--metric': `var(--monny-metric-${metric})` } as CSSProperties) : undefined
      }
    >
      <div className={styles.text}>
        {typeof eyebrow === 'string' ? <p className={styles.eyebrow}>{eyebrow}</p> : eyebrow}
        <h2 id={`${id}-title`} className={styles.title}>
          {title}
        </h2>
        <p className={styles.lead}>{lead}</p>
      </div>
      <div className={styles.visual}>{children}</div>
      {extras && <div className={styles.extras}>{extras}</div>}
    </section>
  )
}

export function FeatureCard({ className, ...props }: ComponentProps<typeof Card>) {
  return <Card className={className ? `${styles.card} ${className}` : styles.card} {...props} />
}

/** A small card beside the section text, under the lead. */
export function SideCard({ className, ...props }: ComponentProps<typeof Card>) {
  return (
    <Card
      className={
        className ? `${styles.card} ${styles.side} ${className}` : `${styles.card} ${styles.side}`
      }
      {...props}
    />
  )
}

export function CardLabel({ children }: { children: ReactNode }) {
  return <p className={styles.cardLabel}>{children}</p>
}

/** Rows like “Click → Opens the popover”. */
export function ResultRows({ rows }: { rows: readonly (readonly [string, string])[] }) {
  return (
    <dl className={styles.rows}>
      {rows.map(([key, result]) => (
        <div key={key}>
          <dt>{key}</dt>
          <dd>{result}</dd>
        </div>
      ))}
    </dl>
  )
}

export function Note({ children }: { children: ReactNode }) {
  return <p className={styles.note}>{children}</p>
}

/** Single-select chips that switch an illustration; one option always stays selected. */
export function ChoiceChips<Value extends string>({
  label,
  options,
  value,
  onValueChange,
}: {
  label: string
  options: readonly (readonly [Value, string])[]
  value: Value
  onValueChange: (value: Value) => void
}) {
  return (
    <ToggleGroup
      aria-label={label}
      className={styles.chips}
      value={[value]}
      deselectable={false}
      onValueChange={(details) => {
        const next = details.value[0] as Value | undefined
        if (next) onValueChange(next)
      }}
    >
      {options.map(([option, text]) => (
        <ToggleGroupItem key={option} value={option} size="sm" className={styles.chip}>
          {text}
        </ToggleGroupItem>
      ))}
    </ToggleGroup>
  )
}

/** Multi-select chips: each one turns a part of the illustration on or off. */
export function ToggleChips<Value extends string>({
  label,
  options,
  value,
  onValueChange,
}: {
  label: string
  options: readonly (readonly [Value, string])[]
  value: readonly Value[]
  onValueChange: (value: Value[]) => void
}) {
  return (
    <ToggleGroup
      aria-label={label}
      className={styles.chips}
      multiple
      value={[...value]}
      onValueChange={(details) => onValueChange(details.value as Value[])}
    >
      {options.map(([option, text]) => (
        <ToggleGroupItem key={option} value={option} size="sm" className={styles.chip}>
          {text}
        </ToggleGroupItem>
      ))}
    </ToggleGroup>
  )
}
