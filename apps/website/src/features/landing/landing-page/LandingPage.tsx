import { Button } from '@moduix/react/button'
import { ArrowUpRight } from 'lucide-react'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './LandingPage.module.css'

export function LandingPage() {
  return (
    <div className={styles.content}>
      <h1>{m.heading()}</h1>
      <p>{m.description()}</p>
      <Button asChild size="lg">
        <a href={site.repository}>
          {m.github()}
          <ArrowUpRight aria-hidden="true" size={18} />
        </a>
      </Button>
    </div>
  )
}
