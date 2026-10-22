import { AppWindow, Reveal, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Dashboard.module.css'

export function Dashboard() {
  return (
    <Section id="dashboard">
      <SectionHeading title={m.dashboard_title()} lead={m.dashboard_lead()} centered />
      <Reveal className={styles.window}>
        <AppWindow />
      </Reveal>
    </Section>
  )
}
