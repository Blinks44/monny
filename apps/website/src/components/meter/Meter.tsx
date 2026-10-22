import { ProgressLinear, ProgressLinearRange, ProgressLinearTrack } from '@moduix/react/progress-linear'
import type { ReactNode } from 'react'

/** A moduix progress bar for a reading; its color and size come from the caller's CSS. */
export function Meter(props: { value: number; label: string; orientation?: 'horizontal' | 'vertical'; className?: string; children?: ReactNode }) {
  return (
    <ProgressLinear value={props.value} orientation={props.orientation} className={props.className}>
      <ProgressLinearTrack aria-label={props.label}>
        <ProgressLinearRange />
      </ProgressLinearTrack>
      {props.children}
    </ProgressLinear>
  )
}
