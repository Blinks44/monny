import { site } from '@/config/site'
import {
  baseLocale,
  type Locale,
  locales,
  localizeUrl,
} from '@/integrations/i18n/paraglide/runtime'

export { type Locale, locales }
export const defaultLocale = baseLocale

export const siteRoutes = [
  '/',
  '/alternatives/istat-menus/',
  '/alternatives/aldente/',
  '/guides/ai-coding-quotas/',
  '/guides/port-pid-finder/',
] as const

export type SiteRoutePath = (typeof siteRoutes)[number]

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

function normalizePath(path: string): string {
  if (!path || path === '/') return '/'
  const withLeading = path.startsWith('/') ? path : `/${path}`
  return withLeading.endsWith('/') ? withLeading : `${withLeading}/`
}

export function localePath(locale: Locale, path = '/') {
  return localizeUrl(new URL(normalizePath(path), site.origin), { locale }).pathname
}
