import { Chart, ChartHeader, ChartLegend, ChartLegendItem, ChartPlot, ChartTitle } from '@moduix/react/chart'
import { areaY, defineChart, lineY } from '@tanstack/charts'
import { scaleLinear } from '@tanstack/charts/scales/linear'
import { scalePoint } from '@tanstack/charts/scales/point'
import { tooltip } from '@tanstack/charts/tooltip'
import { clsx } from 'clsx'
import { Activity, Battery, Cpu, Globe, HardDrive, type LucideIcon, MemoryStick, Thermometer } from 'lucide-react'
import { formatPercent, formatUnit } from '~/lib/format'
import { type Metric, tint } from '~/lib/metrics'
import { m } from '~/paraglide/messages.js'
import { MetricIcon } from '../metric-icon/MetricIcon'
import { Sparkline, smooth } from '../sparkline/Sparkline'
import styles from './AppWindow.module.css'

/** One sample hour of CPU load (%) and CPU temperature (°C), drawn after `01 · Window · Overview`. */
const hour = [
  { time: '10:00', load: 22, temperature: 48 },
  { time: '10:05', load: 30, temperature: 50 },
  { time: '10:10', load: 26, temperature: 49 },
  { time: '10:15', load: 44, temperature: 56 },
  { time: '10:20', load: 38, temperature: 55 },
  { time: '10:25', load: 58, temperature: 62 },
  { time: '10:30', load: 88, temperature: 71 },
  { time: '10:35', load: 54, temperature: 64 },
  { time: '10:40', load: 32, temperature: 56 },
  { time: '10:45', load: 26, temperature: 52 },
  { time: '10:50', load: 34, temperature: 54 },
  { time: '10:55', load: 30, temperature: 53 },
]

/** A rendition of the dashboard window's Overview page; the chart and its tooltip are moduix Chart. */
export function AppWindow() {
  const load = m.window_chart_load()
  const temperature = m.window_chart_temperature()
  const definition = defineChart({
    marks: [
      areaY(hour, { x: 'time', y: 'load', color: () => load, fillOpacity: 0.18, curve: smooth }),
      lineY(hour, { x: 'time', y: 'load', color: () => load, strokeWidth: 2, curve: smooth }),
      lineY(hour, { x: 'time', y: 'temperature', color: () => temperature, strokeWidth: 2, curve: smooth }),
    ],
    scales: {
      x: { scale: scalePoint },
      y: { scale: scaleLinear().domain([0, 100]), grid: true },
    },
    color: { domain: [load, temperature], range: ['var(--monny-cpu)', 'var(--monny-heat)'] },
    focus: 'group-x',
    tooltip,
  })
  return (
    <div className={styles.window}>
      <aside className={styles.sidebar} aria-hidden>
        <div className={styles.trafficLights}>
          <i />
          <i />
          <i />
        </div>
        <div className={styles.overline}>{m.window_monitor()}</div>
        <SidebarItem icon={Activity} metric="graphite" title={m.tab_overview()} selected />
        <SidebarItem icon={Cpu} metric="cpu" title={m.metric_cpu()} />
        <SidebarItem icon={MemoryStick} metric="memory" title={m.metric_memory()} />
        <SidebarItem icon={HardDrive} metric="disk" title={m.metric_disk()} />
        <SidebarItem icon={Globe} metric="network" title={m.metric_network()} />
        <SidebarItem icon={Battery} metric="battery" title={m.tab_battery()} />
        <SidebarItem icon={Thermometer} metric="heat" title={m.metric_sensors()} />
      </aside>
      <div className={styles.main}>
        <div>
          <div className={styles.title}>{m.tab_overview()}</div>
          <div className={styles.subtitle}>{m.window_machine()}</div>
        </div>
        <div className={styles.summary}>
          <Summary icon={Cpu} metric="cpu" title={m.metric_cpu()} value={formatPercent(34)} note={m.window_cpu_note()} points={hour.map((point) => point.load)} />
          <Summary icon={MemoryStick} metric="memory" title={m.metric_memory()} value={formatUnit(11.2, 'gigabyte', 1)} note={m.window_memory_note()} points={[60, 61, 60, 62, 63, 62, 64, 63, 62, 63, 64, 62]} />
          <Summary icon={Thermometer} metric="heat" title={m.metric_temperature()} value={formatUnit(52, 'celsius')} note={m.window_temperature_note()} points={hour.map((point) => point.temperature)} />
          <Summary icon={Battery} metric="battery" title={m.tab_battery()} value={formatPercent(80)} note={m.window_battery_note()} points={[40, 48, 56, 64, 72, 78, 80, 80, 80, 80, 80, 80]} />
        </div>
        <Chart className={clsx(styles.card, styles.chart)}>
          <ChartHeader>
            <ChartTitle className={styles.chartTitle}>{m.window_chart_title()}</ChartTitle>
          </ChartHeader>
          <ChartPlot definition={definition} height={220} ariaLabel={m.window_chart_title()} />
          <ChartLegend aria-label={m.window_chart_title()}>
            <ChartLegendItem color="var(--monny-cpu)">{load}</ChartLegendItem>
            <ChartLegendItem color="var(--monny-heat)">{temperature}</ChartLegendItem>
          </ChartLegend>
        </Chart>
      </div>
    </div>
  )
}

function SidebarItem({ icon, metric, title, selected }: { icon: LucideIcon; metric: Metric; title: string; selected?: boolean }) {
  return (
    <div className={clsx(styles.item, selected && styles.selected)}>
      <MetricIcon icon={icon} metric={metric} /> {title}
    </div>
  )
}

function Summary(props: { icon: LucideIcon; metric: Metric; title: string; value: string; note: string; points: number[] }) {
  return (
    <div className={styles.card} style={tint(props.metric)}>
      <span className={styles.label}>
        <props.icon size={13} aria-hidden /> {props.title}
      </span>
      <span className={styles.value}>{props.value}</span>
      <span className={styles.note}>{props.note}</span>
      <Sparkline points={props.points} color={`var(--monny-${props.metric})`} label={props.title} height={26} />
    </div>
  )
}
