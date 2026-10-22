import { getLocale } from '~/paraglide/runtime.js'

/** Locale-aware numbers for the sample readings, so `34 %` and `412 ГБ` read naturally in every language. */
export const formatPercent = (value: number, digits = 0) =>
  new Intl.NumberFormat(getLocale(), { style: 'percent', minimumFractionDigits: digits, maximumFractionDigits: digits }).format(value / 100)

export const formatUnit = (value: number, unit: string, digits = 0) =>
  new Intl.NumberFormat(getLocale(), { style: 'unit', unit, unitDisplay: 'short', maximumFractionDigits: digits }).format(value)

export const formatNumber = (value: number, digits = 0) =>
  new Intl.NumberFormat(getLocale(), { maximumFractionDigits: digits }).format(value)

export const formatDollars = (value: number) =>
  new Intl.NumberFormat(getLocale(), { style: 'currency', currency: 'USD' }).format(value)

export const formatDuration = (hours: number, minutes: number) => `${formatUnit(hours, 'hour')} ${formatUnit(minutes, 'minute')}`

export const formatDate = (date: Date, options: Intl.DateTimeFormatOptions) => new Intl.DateTimeFormat(getLocale(), options).format(date)
