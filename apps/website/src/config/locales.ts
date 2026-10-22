import { site } from '@/config/site'
import {
  baseLocale,
  type Locale,
  locales,
  localizeUrl,
} from '@/integrations/i18n/paraglide/runtime'

export { type Locale, locales }
export const defaultLocale = baseLocale

export const languageNames: Record<Locale, string> = {
  en: 'English',
  ru: 'Русский',
  de: 'Deutsch',
  fr: 'Français',
  es: 'Español',
  'zh-Hans': '简体中文',
}
export const openGraphLocales: Record<Locale, string> = {
  en: 'en_US',
  ru: 'ru_RU',
  de: 'de_DE',
  fr: 'fr_FR',
  es: 'es_ES',
  'zh-Hans': 'zh_CN',
}
export function localePath(locale: Locale) {
  return localizeUrl(new URL('/', site.origin), { locale }).pathname
}
