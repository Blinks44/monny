import { Heading } from '@moduix/react/heading'
import { Text } from '@moduix/react/text'
import { clsx } from 'clsx'
import { Reveal } from '../reveal/Reveal'
import styles from './SectionHeading.module.css'

export function SectionHeading({ title, lead, centered }: { title: string; lead?: string; centered?: boolean }) {
  return (
    <Reveal className={clsx(styles.heading, centered && styles.centered)}>
      <Heading as="h2" className={styles.title}>
        {title}
      </Heading>
      {lead && <Text className={styles.lead}>{lead}</Text>}
    </Reveal>
  )
}
