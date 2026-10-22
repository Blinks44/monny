import { Badge } from '@moduix/react/badge'
import { clsx } from 'clsx'
import type { ReactNode } from 'react'
import styles from './Chip.module.css'

export function Chip(props: { tone: 'success' | 'warning' | 'info' | 'memory'; large?: boolean; className?: string; children: ReactNode }) {
  return (
    <Badge variant="outline" className={clsx(styles.chip, styles[props.tone], props.large && styles.large, props.className)}>
      {props.children}
    </Badge>
  )
}
