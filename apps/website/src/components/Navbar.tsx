import {
  Drawer,
  DrawerBackdrop,
  DrawerBody,
  DrawerCloseIcon,
  DrawerContent,
  DrawerHeader,
  DrawerPositioner,
  DrawerTitle,
  DrawerTrigger,
} from '@moduix/react/drawer'
import {
  Menu,
  MenuContent,
  MenuItemIndicator,
  MenuItemText,
  MenuPositioner,
  MenuRadioItem,
  MenuRadioItemGroup,
  MenuTrigger,
} from '@moduix/react/menu'
import { Check, ChevronDown, Globe, Menu as MenuIcon, Moon, Sun } from 'lucide-react'
import { useState } from 'react'
import { type Locale, languageNames, locales } from '@/config/locales'

const LOCALE_CODES: Record<Locale, string> = {
  en: 'EN',
  ru: 'RU',
  de: 'DE',
  fr: 'FR',
  es: 'ES',
  'zh-Hans': '中文',
}
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale, setLocale } from '@/integrations/i18n/paraglide/runtime'
import type { ColorScheme } from '@/lib/theme'

function GitHubIcon({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
    </svg>
  )
}

interface NavbarProps {
  theme: ColorScheme
  onToggleTheme: () => void
}

export function Navbar({ theme, onToggleTheme }: NavbarProps) {
  const currentLocale = getLocale() as Locale
  const [drawerOpen, setDrawerOpen] = useState(false)

  const navItems = [
    { href: '#features', label: m.navFeatures() },
    { href: '#bento', label: m.navHardware() },
    { href: '#privacy', label: m.navPrivacy() },
    { href: '#install', label: m.navInstall() },
    { href: '#faq', label: m.navFaq() },
  ]

  const onSelectLocale = (next: string) => {
    if (locales.includes(next as Locale) && next !== currentLocale) {
      void setLocale(next as Locale)
    }
  }

  return (
    <header className="navbar">
      <div className="container navbar-inner">
        <a href="#top" className="brand-link">
          <img src="/app-icon.png" alt={site.name} width={28} height={28} className="brand-icon" />
          <span>{site.name}</span>
        </a>

        <nav className="nav-links" aria-label="Primary">
          {navItems.map((item) => (
            <a key={item.href} href={item.href} className="nav-link">
              {item.label}
            </a>
          ))}
        </nav>

        <div className="nav-actions">
          <Menu>
            <MenuTrigger className="nav-lang-trigger" aria-label={m.navLanguageLabel()}>
              <Globe size={14} aria-hidden="true" />
              <span>{LOCALE_CODES[currentLocale]}</span>
              <ChevronDown size={13} aria-hidden="true" />
            </MenuTrigger>
            <MenuPositioner>
              <MenuContent>
                <MenuRadioItemGroup
                  value={currentLocale}
                  onValueChange={(details) => onSelectLocale(details.value)}
                >
                  {locales.map((loc) => (
                    <MenuRadioItem key={loc} value={loc} className="lang-menu-item">
                      <MenuItemText>
                        <span>{languageNames[loc]}</span>
                      </MenuItemText>
                      <span className="lang-menu-code">
                        {loc === currentLocale ? (
                          <MenuItemIndicator>
                            <Check size={13} aria-hidden="true" />
                          </MenuItemIndicator>
                        ) : (
                          LOCALE_CODES[loc]
                        )}
                      </span>
                    </MenuRadioItem>
                  ))}
                </MenuRadioItemGroup>
              </MenuContent>
            </MenuPositioner>
          </Menu>

          <a
            href={site.repository}
            target="_blank"
            rel="noreferrer"
            className="btn-monny-outline nav-icon-btn nav-github-desktop"
            aria-label={m.navGithub()}
            title={m.navGithub()}
          >
            <GitHubIcon size={16} />
          </a>

          <button
            type="button"
            className="btn-monny-outline nav-icon-btn nav-theme-desktop"
            onClick={onToggleTheme}
            aria-label={m.navThemeToggle()}
            title={m.navThemeToggle()}
          >
            {theme === 'dark' ? (
              <Sun size={16} aria-hidden="true" />
            ) : (
              <Moon size={16} aria-hidden="true" />
            )}
          </button>

          <a href="#install" className="btn-monny-dark nav-download-btn">
            {m.navDownload()}
          </a>

          <Drawer open={drawerOpen} onOpenChange={(details) => setDrawerOpen(details.open)}>
            <DrawerTrigger
              className="btn-monny-outline nav-icon-btn mobile-menu-trigger"
              aria-label={m.navMenuLabel()}
            >
              <MenuIcon size={17} aria-hidden="true" />
            </DrawerTrigger>
            <DrawerBackdrop />
            <DrawerPositioner>
              <DrawerContent>
                <DrawerHeader>
                  <DrawerTitle>{site.name}</DrawerTitle>
                  <DrawerCloseIcon />
                </DrawerHeader>
                <DrawerBody>
                  <div className="drawer-nav-list">
                    {navItems.map((item) => (
                      <a
                        key={item.href}
                        href={item.href}
                        className="drawer-nav-link"
                        onClick={() => setDrawerOpen(false)}
                      >
                        {item.label}
                      </a>
                    ))}
                    <a
                      href={site.repository}
                      target="_blank"
                      rel="noreferrer"
                      className="drawer-nav-link"
                      onClick={() => setDrawerOpen(false)}
                    >
                      <span>{m.navGithub()}</span>
                      <GitHubIcon size={16} />
                    </a>
                    <button
                      type="button"
                      className="drawer-nav-link"
                      style={{
                        border: 0,
                        background: 'transparent',
                        width: '100%',
                        cursor: 'pointer',
                      }}
                      onClick={() => {
                        onToggleTheme()
                        setDrawerOpen(false)
                      }}
                    >
                      <span>{m.navThemeToggle()}</span>
                      {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
                    </button>
                  </div>
                </DrawerBody>
              </DrawerContent>
            </DrawerPositioner>
          </Drawer>
        </div>
      </div>
    </header>
  )
}
