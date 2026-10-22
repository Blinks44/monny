import { Link } from '@tanstack/react-router'
import type { ReactNode } from 'react'
import { LanguageSwitcher } from '@/components/language-switcher'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './PageShell.module.css'

export function PageShell({ children }: { children: ReactNode }) {
  return (
    <div className={styles.shell}>
      <a className={styles.skip} href="#main">
        {m.skip()}
      </a>
      <header className={styles.header}>
        <Link to="/" className={styles.brand}>
          <img src="/app-icon.png" width="32" height="32" alt="" />
          Monny
        </Link>
        <LanguageSwitcher />
      </header>
      <main id="main" className={styles.main} tabIndex={-1}>
        {children}
      </main>
    </div>
  )
}
