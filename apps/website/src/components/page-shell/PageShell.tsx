import { Button } from '@moduix/react/button'
import {
  Drawer,
  DrawerBackdrop,
  DrawerPositioner,
  DrawerContent,
  DrawerTrigger,
  DrawerTitle,
  DrawerCloseTrigger,
} from '@moduix/react/drawer'
import { Link } from '@tanstack/react-router'
import { Menu, X } from 'lucide-react'
import { useState, type ReactNode } from 'react'
import { LanguageSwitcher } from '@/components/language-switcher'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './PageShell.module.css'

export function PageShell({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false)
  const links = [
    ['menu-bar', m.menuBar()],
    ['battery', m.battery()],
    ['ai-limits', m.aiLimits()],
    ['install', m.install()],
    ['faq', m.faq()],
  ] as const
  return (
    <div className={styles.shell}>
      <a className={styles.skip} href="#main">
        {m.skip()}
      </a>
      <header className={styles.header}>
        <div className={styles.headerInner}>
          <Link to="/" className={styles.brand}>
            <img src="/app-icon.png" width="32" height="32" alt="" />
            Monny
          </Link>
          <nav className={styles.navigation} aria-label={m.product()}>
            {links.map(([hash, label]) => (
              <Link key={hash} to="/" hash={hash}>
                {label}
              </Link>
            ))}
          </nav>
          <div className={styles.controls}>
            <LanguageSwitcher variant="header" />
            <Button asChild variant="ghost">
              <a href={site.repository}>GitHub</a>
            </Button>
            <Button asChild>
              <a href={site.downloadUrl ?? site.releases}>{m.downloadShort()}</a>
            </Button>
          </div>
          <div className={styles.mobileMenu}>
            <Drawer swipeDirection="up" open={open} onOpenChange={({ open }) => setOpen(open)}>
              <DrawerTrigger asChild>
                <Button variant="ghost" size="icon-md" aria-label={m.menu()}>
                  <Menu size={22} aria-hidden="true" />
                </Button>
              </DrawerTrigger>
              <DrawerBackdrop />
              <DrawerPositioner className={styles.drawerPositioner}>
                <DrawerContent className={styles.drawer}>
                  <div className={styles.drawerHeader}>
                    <DrawerTitle className={styles.brand}>
                      <img src="/app-icon.png" width="28" height="28" alt="" />
                      Monny
                    </DrawerTitle>
                    <DrawerCloseTrigger asChild>
                      <Button size="icon-md" variant="ghost" aria-label={m.closeMenu()}>
                        <X aria-hidden="true" />
                      </Button>
                    </DrawerCloseTrigger>
                  </div>
                  <nav className={styles.drawerLinks} aria-label={m.menu()}>
                    {links.map(([hash, label]) => (
                      <Link key={hash} to="/" hash={hash} onClick={() => setOpen(false)}>
                        {label}
                      </Link>
                    ))}
                    <a href={site.repository}>GitHub ↗</a>
                  </nav>
                  <div className={styles.drawerFooter}>
                    <LanguageSwitcher variant="drawer" />
                    <Button asChild size="xl">
                      <a href={site.downloadUrl ?? site.releases}>{m.download()}</a>
                    </Button>
                    <Link to="/" hash="install" onClick={() => setOpen(false)}>
                      {m.drawerInstallLink()}
                    </Link>
                  </div>
                </DrawerContent>
              </DrawerPositioner>
            </Drawer>
          </div>
        </div>
      </header>
      <main id="main" className={styles.main} tabIndex={-1}>
        {children}
      </main>
    </div>
  )
}
