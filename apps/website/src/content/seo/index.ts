import type { Locale } from '@/config/locales'
import { deSeoContent } from './de'
import { enSeoContent } from './en'
import { esSeoContent } from './es'
import { frSeoContent } from './fr'
import { ruSeoContent } from './ru'
import type {
  AlternativePageData,
  AlternativeSlug,
  GuidePageData,
  GuideSlug,
  LocaleSeoContent,
} from './types'
import { zhHansSeoContent } from './zh-Hans'

const byLocale: Record<Locale, LocaleSeoContent> = {
  en: enSeoContent,
  ru: ruSeoContent,
  de: deSeoContent,
  es: esSeoContent,
  fr: frSeoContent,
  'zh-Hans': zhHansSeoContent,
}

export function getAlternativeContent(locale: Locale, slug: AlternativeSlug): AlternativePageData {
  return byLocale[locale].alternatives[slug]
}

export function getGuideContent(locale: Locale, slug: GuideSlug): GuidePageData {
  return byLocale[locale].guides[slug]
}

export type {
  AlternativePageData,
  AlternativeSlug,
  ComparisonRow,
  FitCard,
  GuideCard,
  GuidePageData,
  GuideSlug,
  HighlightMetric,
  LocaleSeoContent,
  SafetyItem,
  StepCard,
} from './types'
