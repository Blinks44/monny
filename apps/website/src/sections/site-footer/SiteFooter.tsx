import { Container } from '@moduix/react/container'
import { site } from '~/lib/site'
import { m } from '~/paraglide/messages.js'
import styles from './SiteFooter.module.css'

export function SiteFooter() {
  return (
    <Container asChild size="lg">
      <footer className={styles.footer}>
        <span>© 2026 Monny · MIT</span>
        <a href={`https://github.com/${site.githubRepo}`}>GitHub</a>
        <span>{m.requirement()}</span>
      </footer>
    </Container>
  )
}
