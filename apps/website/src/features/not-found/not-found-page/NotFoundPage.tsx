import { Button } from '@moduix/react/button'
import { Link } from '@tanstack/react-router'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './NotFoundPage.module.css'

export function NotFoundPage() {
  return (
    <div className={styles.content}>
      <p className={styles.code}>404</p>
      <h1>{m.notFoundHeading()}</h1>
      <p>{m.notFoundDescription()}</p>
      <Button asChild size="lg">
        <Link to="/">{m.home()}</Link>
      </Button>
    </div>
  )
}
