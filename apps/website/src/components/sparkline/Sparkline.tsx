import { ChartPlot } from '@moduix/react/chart'
import { areaY, defineChart, lineY } from '@tanstack/charts'
import { d3Curve } from '@tanstack/charts/d3/shape'
import { scaleLinear } from '@tanstack/charts/scales/linear'
import { curveMonotoneX } from 'd3-shape'

/** The smooth curve of the app's charts. */
export const smooth = d3Curve(curveMonotoneX)

/** A small area chart of percentages (0–100) without axes, like the app's card sparklines. */
export function Sparkline({ points, color, label, height = 36 }: { points: number[]; color: string; label: string; height?: number }) {
  const data = points.map((value, index) => ({ index, value }))
  const definition = defineChart({
    marks: [
      areaY(data, { x: 'index', y: 'value', fill: color, fillOpacity: 0.16, curve: smooth }),
      lineY(data, { x: 'index', y: 'value', stroke: color, strokeWidth: 1.8, curve: smooth }),
    ],
    scales: { x: { scale: scaleLinear }, y: { scale: scaleLinear().domain([0, 100]) } },
    guides: false,
    margin: 2,
  })
  return <ChartPlot definition={definition} height={height} ariaLabel={label} motion={false} />
}
