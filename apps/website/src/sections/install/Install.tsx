import { Heading } from '@moduix/react/heading'
import { Text } from '@moduix/react/text'
import { ShieldAlert } from 'lucide-react'
import { InstallCommand, Reveal, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Install.module.css'

/**
 * Monny is signed but not notarized until the project has a paid Developer ID, so the first launch
 * needs one approval. Remove the callout once releases are notarized (README › Install).
 */
export function Install() {
  const steps = [
    { title: m.step1_title(), text: m.step1_text() },
    { title: m.step2_title(), text: m.step2_text() },
    { title: m.step3_title(), text: m.step3_text() },
  ]
  return (
    <Section id="install">
      <SectionHeading title={m.install_title()} />
      <ol className={styles.steps}>
        {steps.map((step, index) => (
          <li key={step.title}>
            <Reveal delay={index * 0.1}>
              <span className={styles.number} aria-hidden>
                {index + 1}
              </span>
              <Heading as="h3" className={styles.title}>
                {step.title}
              </Heading>
              <Text className={styles.text}>{step.text}</Text>
            </Reveal>
          </li>
        ))}
      </ol>
      <Reveal className={styles.callout}>
        <ShieldAlert size={24} aria-hidden />
        <Heading as="h3" className={styles.calloutTitle}>
          {m.unverified_title()}
        </Heading>
        <Text className={styles.calloutText}>{m.unverified_text()}</Text>
        <div className={styles.command}>
          <InstallCommand />
          <small>{m.unverified_once()}</small>
        </div>
      </Reveal>
    </Section>
  )
}
