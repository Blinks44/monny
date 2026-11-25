import type { SiteRoutePath } from '@/config/locales'

export type AlternativeSlug = 'istat-menus' | 'aldente'
export type GuideSlug = 'ai-coding-quotas' | 'port-pid-finder'

export interface HighlightMetric {
  value: string
  label: string
}

export interface ComparisonRow {
  criterion: string
  monny: string
  other: string
}

export interface FitCard {
  label: string
  title: string
  points: [string, string, string]
}

export interface StepCard {
  step: string
  title: string
  description: string
}

export interface AlternativePageData {
  slug: AlternativeSlug
  path: SiteRoutePath
  breadcrumbLabel: string
  metaTitle: string
  metaDescription: string
  headline: string
  subtitle: string
  highlights: [HighlightMetric, HighlightMetric, HighlightMetric]
  competitorColumn: string
  rows: ComparisonRow[]
  chooseMonny: FitCard
  stickWithOther: FitCard
  steps: [StepCard, StepCard, StepCard]
}

export interface GuideCard {
  label: string
  title: string
  description: string
  items: [string, string, string]
  footer: string
}

export interface SafetyItem {
  title: string
  description: string
}

export interface GuidePageData {
  slug: GuideSlug
  path: SiteRoutePath
  breadcrumbLabel: string
  metaTitle: string
  metaDescription: string
  headline: string
  subtitle: string
  secondaryCtaLabel: string
  secondaryCtaTo: SiteRoutePath
  cardsTitle: string
  cards: [GuideCard, GuideCard, GuideCard]
  stepsTitle: string
  steps: [StepCard, StepCard, StepCard, StepCard]
  guarantees: [SafetyItem, SafetyItem, SafetyItem]
}

export interface LocaleSeoContent {
  alternatives: Record<AlternativeSlug, AlternativePageData>
  guides: Record<GuideSlug, GuidePageData>
}
