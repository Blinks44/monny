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
import { Check, ChevronDown, Globe, Menu as MenuIcon, Moon, Star, Sun } from 'lucide-react'
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
          <a
            href={site.repository}
            target="_blank"
            rel="noreferrer"
            className="btn-monny-outline nav-github-desktop"
          >
            <Star size={14} aria-hidden="true" />
            <span>{m.navGithub()}</span>
          </a>

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
                      <Star size={15} aria-hidden="true" />
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
