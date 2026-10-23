import {
  Menu,
  MenuContent,
  MenuItemGroup,
  MenuItemGroupLabel,
  MenuItemIndicator,
  MenuItemText,
  MenuPositioner,
  MenuRadioItem,
  MenuRadioItemGroup,
  MenuTrigger,
  MenuTriggerIcon,
  MenuViewport,
} from '@moduix/react/menu'
import { languageNames, localePath, type Locale } from '@/config/locales'
import { m } from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import styles from './LanguageSwitcher.module.css'

const languageOrder = ['en', 'de', 'es', 'fr', 'ru', 'zh-Hans'] satisfies Locale[]

export function LanguageSwitcher({
  variant = 'footer',
}: {
  variant?: 'header' | 'footer' | 'drawer'
}) {
  const currentLocale = getLocale()
  return (
    <Menu positioning={{ placement: variant === 'header' ? 'bottom-end' : 'top-end', gutter: 8 }}>
      <MenuTrigger
        className={`${styles.trigger} ${styles[variant]}`}
        aria-label={`${m.language()}: ${languageNames[currentLocale]}`}
      >
        <span lang={currentLocale}>
          {variant === 'header'
            ? currentLocale.slice(0, 2).toUpperCase()
            : languageNames[currentLocale]}
        </span>
        <MenuTriggerIcon />
      </MenuTrigger>
      <MenuPositioner>
        <MenuContent
          className={`${styles.content} ${variant === 'drawer' ? styles.drawerMenu : ''}`}
          aria-label={m.language()}
        >
          <MenuViewport className={styles.viewport}>
            <MenuItemGroup>
              <MenuItemGroupLabel className={styles.label}>{m.language()}</MenuItemGroupLabel>
              <MenuRadioItemGroup value={currentLocale} aria-label={m.language()}>
                {languageOrder.map((locale) => (
                  <MenuRadioItem key={locale} value={locale} indicator="end" asChild>
                    <a href={localePath(locale)} lang={locale} hrefLang={locale}>
                      <MenuItemText className={styles.itemText}>
                        <span>{languageNames[locale]}</span>
                        <span className={styles.code} aria-hidden="true">
                          {locale.slice(0, 2).toUpperCase()}
                        </span>
                      </MenuItemText>
                      <MenuItemIndicator />
                    </a>
                  </MenuRadioItem>
                ))}
              </MenuRadioItemGroup>
            </MenuItemGroup>
          </MenuViewport>
        </MenuContent>
      </MenuPositioner>
    </Menu>
  )
}
