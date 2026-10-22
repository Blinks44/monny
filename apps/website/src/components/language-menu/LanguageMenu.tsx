import { Button } from '@moduix/react/button'
import { Menu, MenuContent, MenuIndicator, MenuItem, MenuPositioner, MenuTrigger } from '@moduix/react/menu'
import { Check, Globe } from 'lucide-react'
import { m } from '~/paraglide/messages.js'
import { type Locale, getLocale, locales, localizeHref, setLocale } from '~/paraglide/runtime.js'
import styles from './LanguageMenu.module.css'

const names: Record<Locale, string> = {
  en: 'English',
  ru: 'Русский',
  de: 'Deutsch',
  fr: 'Français',
  es: 'Español',
  'zh-Hans': '简体中文',
}

/**
 * Each language is a link to its own URL, so crawlers can follow it. The menu closes before the browser
 * would follow the link, so the actual navigation goes through the menu's `navigate` hook.
 */
export function LanguageMenu() {
  const current = getLocale()
  return (
    <Menu positioning={{ placement: 'bottom-end' }} navigate={({ value }) => setLocale(value as Locale)}>
      <MenuTrigger asChild>
        <Button variant="outline" size="sm" className={styles.trigger} aria-label={`${m.language()}: ${names[current]}`}>
          <Globe size={15} aria-hidden />
          <span>{names[current]}</span>
          <MenuIndicator />
        </Button>
      </MenuTrigger>
      <MenuPositioner>
        <MenuContent className={styles.menu}>
          {locales.map((locale) => (
            <MenuItem key={locale} value={locale} className={styles.item} asChild>
              <a href={localizeHref('/', { locale })} hrefLang={locale} lang={locale} aria-current={locale === current || undefined}>
                {names[locale]}
                {locale === current && <Check size={15} className={styles.check} aria-hidden />}
              </a>
            </MenuItem>
          ))}
        </MenuContent>
      </MenuPositioner>
    </Menu>
  )
}
