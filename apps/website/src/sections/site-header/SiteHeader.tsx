import { Button } from '@moduix/react/button'
import { Container } from '@moduix/react/container'
import { LanguageMenu, Logo } from '~/components'
import { m } from '~/paraglide/messages.js'
import { localizeHref } from '~/paraglide/runtime.js'
import styles from './SiteHeader.module.css'

/** Links point at the landing page's anchors, so they also work from other pages such as 404. */
export function SiteHeader() {
  const home = localizeHref('/')
  return (
    <header className={styles.header}>
      <Container size="lg" className={styles.row}>
        <a className={styles.brand} href={`${home}#top`}>
          <Logo size={34} />
          Monny
        </a>
        <nav className={styles.nav} aria-label={m.nav_sections()}>
          <a href={`${home}#features`}>{m.nav_features()}</a>
          <a href={`${home}#battery`}>{m.nav_battery()}</a>
          <a href={`${home}#ai`}>{m.nav_ai()}</a>
          <a href={`${home}#install`}>{m.nav_install()}</a>
          <a href={`${home}#faq`}>{m.nav_faq()}</a>
        </nav>
        <LanguageMenu />
        <Button asChild size="sm" className={styles.download}>
          <a href={`${home}#download`}>{m.nav_download()}</a>
        </Button>
      </Container>
    </header>
  )
}
