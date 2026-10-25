import { Card } from '@moduix/react/card'
import { Link } from '@tanstack/react-router'
import rebindWebp from '@/assets/product/rebind.webp'
import rebindPng from '@/assets/product/rebind.png'
import { LanguageSwitcher } from '@/components/language-switcher'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './SiteFooter.module.css'

export function SiteFooter() {
  return (
    <footer className={styles.footer}>
      <div className={styles.top}>
        <div className={styles.about}>
          <Link to="/" className={styles.brand}>
            <img src="/app-icon.png" width="28" height="28" alt="" />
            Monny
          </Link>
          <p>{m.footerTagline()}</p>
        </div>
        <nav aria-label={m.product()}>
          <h2>{m.product()}</h2>
          <Link to="/" hash="features">
            {m.features()}
          </Link>
          <Link to="/" hash="battery">
            {m.battery()}
          </Link>
          <Link to="/" hash="install">
            {m.install()}
          </Link>
          <a href={site.releases}>{m.changelog()}</a>
        </nav>
        <nav aria-label={m.project()}>
          <h2>{m.project()}</h2>
          <a href={site.repository}>GitHub</a>
          <a href={site.releases}>{m.releases()}</a>
          <a href={`${site.repository}/issues`}>{m.reportIssue()}</a>
          <a href={`${site.repository}/blob/main/LICENSE`}>{m.license()}</a>
        </nav>
        <div className={styles.related}>
          <h2>{m.alsoFromUs()}</h2>
          <Card asChild className={styles.rebind}>
            <a href="https://rebind.moduix.dev" aria-label={`Rebind: ${m.rebindDescription()}`}>
              <picture>
                <source srcSet={rebindWebp} type="image/webp" />
                <img src={rebindPng} width="60" height="60" alt="" loading="lazy" />
              </picture>
              <div>
                <strong>Rebind</strong>
                <p>{m.rebindDescription()}</p>
              </div>
            </a>
          </Card>
        </div>
      </div>
      <div className={styles.bottom}>
        <small>{m.legal()}</small>
        <LanguageSwitcher />
      </div>
    </footer>
  )
}
