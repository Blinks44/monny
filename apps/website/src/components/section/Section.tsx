import { Container } from '@moduix/react/container'
import { clsx } from 'clsx'
import type { ReactNode } from 'react'
import styles from './Section.module.css'

/** A page section on the shared content width; `narrow` is the reading column for centered blocks. */
export function Section(props: { id?: string; narrow?: boolean; flush?: boolean; className?: string; children: ReactNode }) {
  return (
    <Container asChild size={props.narrow ? 'sm' : 'lg'}>
      <section id={props.id} className={clsx(!props.flush && styles.section, props.className)}>
        {props.children}
      </section>
    </Container>
  )
}
