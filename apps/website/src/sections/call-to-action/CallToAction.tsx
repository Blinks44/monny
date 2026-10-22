import { Heading } from '@moduix/react/heading'
import { Text } from '@moduix/react/text'
import { DownloadButton, DownloadNote, Logo, Reveal, Section } from '~/components'
import type { Release } from '~/lib/release'
import { m } from '~/paraglide/messages.js'
import styles from './CallToAction.module.css'

export function CallToAction({ release }: { release: Release | null }) {
  return (
    <Section id="download">
      <Reveal className={styles.panel}>
        <Logo size={88} />
        <Heading as="h2" className={styles.title}>
          {m.cta_title()}
        </Heading>
        <Text className={styles.lead}>{m.cta_text()}</Text>
        <div className={styles.button}>
          <DownloadButton release={release} inverted />
        </div>
        <DownloadNote release={release} inverted />
      </Reveal>
    </Section>
  )
}
