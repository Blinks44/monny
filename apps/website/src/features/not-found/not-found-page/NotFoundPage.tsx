import { Button } from '@moduix/react/button'
import { Card } from '@moduix/react/card'
import { Empty } from '@moduix/react/empty'
import { Link } from '@tanstack/react-router'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './NotFoundPage.module.css'

export function NotFoundPage() {
  return (
    <div className={styles.page}>
      <Empty className={styles.content}>
        <Card className={styles.sensor} aria-hidden="true">
          <div className={styles.sensorLabel}>
            <span>{m.emptyPage()}</span>
            <span>{m.emptyBadge()}</span>
          </div>
          <strong>{m.emptyTitle()}</strong>
          <p>{m.emptyDescription()}</p>
          <div className={styles.line} />
        </Card>
        <p className={styles.code}>404</p>
        <h1>{m.notFoundHeading()}</h1>
        <p className={styles.lead}>{m.notFoundDescription()}</p>
        <div className={styles.actions}>
          <Button asChild size="xl">
            <Link to="/">{m.home()}</Link>
          </Button>
          <Button asChild variant="outline" size="xl">
            <a href={site.downloadUrl ?? site.releases}>{m.download()}</a>
          </Button>
        </div>
        <nav className={styles.links} aria-label={m.product()}>
          <Link to="/" hash="menu-bar">
            {m.menuBar()}
          </Link>
          <Link to="/" hash="install">
            {m.install()}
          </Link>
          <Link to="/" hash="faq">
            {m.faq()}
          </Link>
          <a href={site.repository}>GitHub</a>
        </nav>
      </Empty>
      <footer className={styles.footer}>{m.legal()}</footer>
    </div>
  )
}
