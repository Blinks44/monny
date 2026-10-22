import type { CSSProperties } from 'react'

/** The app's metric colors; a metric keeps its color everywhere on the page, as in the app. */
export type Metric = 'cpu' | 'memory' | 'disk' | 'network' | 'upload' | 'battery' | 'heat' | 'accent' | 'graphite'

export const tint = (metric: Metric) => ({ '--tint': `var(--monny-${metric})` }) as CSSProperties
