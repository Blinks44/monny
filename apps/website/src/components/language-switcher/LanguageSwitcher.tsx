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

export function LanguageSwitcher({
  compact = false,
  upward = false,
}: {
  compact?: boolean
  upward?: boolean
}) {
  const currentLocale = getLocale()
  return (
    <Menu positioning={{ placement: upward ? 'top-end' : 'bottom-end' }}>
      <MenuTrigger
        className={compact ? styles.compact : styles.trigger}
        aria-label={`${m.language()}: ${languageNames[currentLocale]}`}
      >
        <span lang={currentLocale}>
          {compact
            ? ({ en: 'EN', ru: 'RU', de: 'DE', fr: 'FR', es: 'ES', 'zh-Hans': '中文' } as const)[
                currentLocale
              ]
            : languageNames[currentLocale]}
        </span>
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
