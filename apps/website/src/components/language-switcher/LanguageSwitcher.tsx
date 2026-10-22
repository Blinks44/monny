import {
  Menu,
  MenuContent,
  MenuItemIndicator,
  MenuItemText,
  MenuPositioner,
  MenuRadioItem,
  MenuRadioItemGroup,
  MenuTrigger,
  MenuTriggerIcon,
} from '@moduix/react/menu'
import { languageNames, localePath, locales } from '@/config/locales'
import { m } from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import styles from './LanguageSwitcher.module.css'

export function LanguageSwitcher() {
  const currentLocale = getLocale()
  return (
    <Menu positioning={{ placement: 'bottom-end' }}>
      <MenuTrigger
        className={styles.trigger}
        aria-label={`${m.language()}: ${languageNames[currentLocale]}`}
      >
        <span lang={currentLocale}>{languageNames[currentLocale]}</span>
        <MenuTriggerIcon />
      </MenuTrigger>
      <MenuPositioner>
        <MenuContent aria-label={m.language()}>
          <MenuRadioItemGroup value={currentLocale} aria-label={m.language()}>
            {locales.map((locale) => (
              <MenuRadioItem key={locale} value={locale} asChild>
                <a href={localePath(locale)} lang={locale} hrefLang={locale}>
                  <MenuItemIndicator />
                  <MenuItemText>{languageNames[locale]}</MenuItemText>
                </a>
              </MenuRadioItem>
            ))}
          </MenuRadioItemGroup>
        </MenuContent>
      </MenuPositioner>
    </Menu>
  )
}
