import { Switch, SwitchControl, SwitchHiddenInput } from '@moduix/react/switch'
import { Tabs, TabsContent, TabsIndicator, TabsList, TabsTrigger } from '@moduix/react/tabs'
import { clsx } from 'clsx'
import { ArrowDown, ArrowUp, Cpu, Globe, HardDrive, MemoryStick, Settings, SquareArrowOutUpRight, Thermometer } from 'lucide-react'
import { type ReactNode, useState } from 'react'
import { aiTools } from '~/lib/ai'
import { formatNumber, formatPercent, formatUnit } from '~/lib/format'
import { type Metric, tint } from '~/lib/metrics'
import { m } from '~/paraglide/messages.js'
import { AiToolCard } from '../ai-tool-card/AiToolCard'
import { ChargeLimit } from '../charge-limit/ChargeLimit'
import { Chip } from '../chip/Chip'
import { Logo } from '../logo/Logo'
import { Meter } from '../meter/Meter'
import { RingGauge } from '../ring-gauge/RingGauge'
import { Sparkline } from '../sparkline/Sparkline'
import styles from './Popover.module.css'

/**
 * A working HTML rendition of the menu bar popover with sample readings. The tabs are a moduix tab list,
 * so switching, the selection indicator and keyboard navigation come from Ark.
 */
export function Popover() {
  return (
    <div className={styles.panel}>
      <div className={styles.header}>
        <Logo size={34} />
        <div>
          <strong>Monny</strong>
          <small>{m.popover_machine()}</small>
        </div>
        <div className={styles.headerButtons} aria-hidden>
          <span>
            <SquareArrowOutUpRight size={14} />
          </span>
          <span>
            <Settings size={14} />
          </span>
        </div>
      </div>
      <Tabs defaultValue="overview" aria-label={m.popover_label()}>
        <TabsList className={styles.list}>
          <TabsIndicator />
          <TabsTrigger value="overview" className={styles.tab}>
            {m.tab_overview()}
          </TabsTrigger>
          <TabsTrigger value="battery" className={styles.tab}>
            {m.tab_battery()}
          </TabsTrigger>
          <TabsTrigger value="processes" className={styles.tab}>
            {m.tab_processes()}
          </TabsTrigger>
          <TabsTrigger value="ai" className={styles.tab}>
            {m.tab_ai()}
          </TabsTrigger>
        </TabsList>
        <TabsContent value="overview" className={styles.content}>
          <Overview />
        </TabsContent>
        <TabsContent value="battery" className={styles.content}>
          <div className={styles.card}>
            <ChargeLimit />
          </div>
        </TabsContent>
        <TabsContent value="processes" className={styles.content}>
          <Processes />
        </TabsContent>
        <TabsContent value="ai" className={clsx(styles.content, styles.scroll)}>
          {aiTools().map((tool) => (
            <AiToolCard key={tool.service} tool={tool} />
          ))}
        </TabsContent>
      </Tabs>
      <div className={styles.footer}>
        <span>
          {m.popover_open_dashboard()}
          <kbd>⌥⌘M</kbd>
        </span>
        <span>{m.popover_updated({ interval: formatUnit(2, 'second') })}</span>
      </div>
    </div>
  )
}

/** Sample readings drawn after `01 · Popover · Overview` in Monny.sketch. */
const cores = [62, 55, 40, 58, 30, 50, 34, 22, 38, 20, 28, 20]
const network = [22, 30, 26, 38, 30, 46, 34, 58, 42, 52, 36, 48, 40, 60]

function Overview() {
  const [limitOn, setLimitOn] = useState(true)
  return (
    <div className={styles.grid}>
      <div className={clsx(styles.card, styles.center)}>
        <CardHead icon={Cpu} title={m.metric_cpu()}>
          <Chip tone="warning">
            <Thermometer size={11} aria-hidden />
            {formatUnit(52, 'celsius')}
          </Chip>
        </CardHead>
        <RingGauge value={34} metric="cpu" label={m.metric_cpu()} unit={m.gauge_load()} />
        <span className={styles.caption}>
          P {formatPercent(41)} · E {formatPercent(27)}
        </span>
      </div>
      <div className={clsx(styles.card, styles.center)}>
        <CardHead icon={MemoryStick} title={m.metric_memory()}>
          <Chip tone="memory">{m.memory_normal()}</Chip>
        </CardHead>
        <RingGauge value={62} metric="memory" label={m.metric_memory()} unit={m.gauge_used()} />
        <span className={styles.caption}>{m.memory_of({ used: formatNumber(11.2, 1), total: formatUnit(18, 'gigabyte') })}</span>
      </div>
      <div className={styles.card}>
        <CardHead icon={HardDrive} title={m.metric_disk()} />
        <div>
          <div className={styles.big}>{formatUnit(412, 'gigabyte')}</div>
          <span className={styles.caption}>{m.disk_free_of({ total: formatUnit(1, 'terabyte') })}</span>
        </div>
        <Meter value={59} label={m.metric_disk()} className={styles.disk} />
        <span className={styles.caption}>
          R {formatUnit(12, 'megabyte-per-second')} · W {formatUnit(3, 'megabyte-per-second')}
        </span>
      </div>
      <div className={styles.card}>
        <CardHead icon={Globe} title={m.metric_network()} />
        <div>
          <div className={styles.rate}>
            <ArrowDown size={15} strokeWidth={2.6} aria-hidden />
            {formatUnit(2.4, 'megabyte-per-second', 1)}
          </div>
          <div className={clsx(styles.rate, styles.upload)}>
            <ArrowUp size={12} strokeWidth={2.6} aria-hidden />
            {formatUnit(320, 'kilobyte-per-second')}
          </div>
        </div>
        <Sparkline points={network} color="var(--monny-network)" label={m.metric_network()} height={34} />
      </div>
      <div className={clsx(styles.card, styles.wide)}>
        <div className={styles.cardHead}>
          <span>{m.metric_cores()}</span>
          <span className={styles.legend}>
            <span>
              <i />
              {m.cores_performance({ count: formatNumber(6) })}
            </span>
            <span>
              <i />
              {m.cores_efficiency({ count: formatNumber(6) })}
            </span>
          </span>
        </div>
        <div className={styles.cores}>
          {cores.map((value, index) => (
            <Meter key={index} value={value} label={`${m.metric_cores()} ${index + 1}`} orientation="vertical" className={clsx(styles.core, index >= 6 && styles.efficiency)} />
          ))}
        </div>
      </div>
      <div className={clsx(styles.card, styles.wide, styles.batteryStrip)}>
        <span className={styles.miniBattery} aria-hidden>
          <span />
        </span>
        <div className={styles.batteryText}>
          <strong>{formatPercent(80)}</strong>
          <small>{limitOn ? m.battery_strip_holding({ limit: formatPercent(80) }) : m.battery_strip_charging()}</small>
        </div>
        <Switch className={styles.limitToggle} checked={limitOn} onCheckedChange={({ checked }) => setLimitOn(checked)}>
          {m.battery_limit_toggle()}
          <SwitchControl />
          <SwitchHiddenInput />
        </Switch>
      </div>
    </div>
  )
}

function CardHead({ icon: Icon, title, children }: { icon: typeof Cpu; title: string; children?: ReactNode }) {
  return (
    <div className={styles.cardHead}>
      <span>
        <Icon size={14} aria-hidden /> {title}
      </span>
      {children}
    </div>
  )
}

const processes: { name: string; letter: string; color: Metric; detail: () => string; cpu: number }[] = [
  { name: 'Xcode', letter: 'X', color: 'network', detail: () => m.processes_count({ count: 4 }), cpu: 14.2 },
  { name: 'Safari', letter: 'S', color: 'accent', detail: () => m.processes_count({ count: 9 }), cpu: 6.1 },
  { name: 'Figma', letter: 'F', color: 'heat', detail: () => m.processes_count({ count: 3 }), cpu: 3.8 },
  { name: 'WindowServer', letter: 'W', color: 'cpu', detail: () => m.processes_system(), cpu: 2.9 },
  { name: 'Music', letter: 'M', color: 'upload', detail: () => m.processes_count({ count: 2 }), cpu: 2.4 },
  { name: 'Mail', letter: 'M', color: 'memory', detail: () => m.processes_count({ count: 2 }), cpu: 0.8 },
]

function Processes() {
  return (
    <div className={styles.card}>
      <div className={styles.cardHead}>
        <span>{m.processes_top()}</span>
        <span className={styles.sort} aria-hidden>
          <span>{m.metric_cpu()}</span>
          <span>{m.metric_memory()}</span>
          <span>{m.processes_energy()}</span>
        </span>
      </div>
      <div>
        {processes.map((process) => (
          <div key={process.name} className={styles.process}>
            <span className={styles.appIcon} style={tint(process.color)} aria-hidden>
              {process.letter}
            </span>
            <span className={styles.processName}>
              {process.name}
              <small>{process.detail()}</small>
            </span>
            <span className={styles.processValue}>{formatPercent(process.cpu, 1)}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
