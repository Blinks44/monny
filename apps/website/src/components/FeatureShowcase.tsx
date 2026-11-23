import {
  Dialog,
  DialogBackdrop,
  DialogBody,
  DialogCloseIcon,
  DialogContent,
  DialogHeader,
  DialogPositioner,
  DialogTitle,
} from '@moduix/react/dialog'
import { Kbd } from '@moduix/react/kbd'
import {
  ProgressLinear,
  ProgressLinearRange,
  ProgressLinearTrack,
} from '@moduix/react/progress-linear'
import {
  Slider,
  SliderControl,
  SliderMarker,
  SliderMarkerGroup,
  SliderRange,
  SliderThumbs,
  SliderTrack,
} from '@moduix/react/slider'
import { Switch, SwitchControl, SwitchHiddenInput, SwitchThumb } from '@moduix/react/switch'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@moduix/react/tabs'
import { BatteryCharging, Check, Image as ImageIcon, RotateCcw, Search, Zap } from 'lucide-react'
import { useState } from 'react'
import { AiLogo, type AiLogoId } from '@/components/AiLogo'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

export type FeatureTabId = 'menubar' | 'cpu' | 'battery' | 'ports' | 'ai' | 'sensors'

interface FeatureShowcaseProps {
  theme: ColorScheme
  activeTab: FeatureTabId
  onTabChange: (tab: FeatureTabId) => void
}

interface PortItem {
  port: string
  process: string
  pid: number
  bind: string
}

const DEMO_PORTS: PortItem[] = [
  { port: ':3002', process: 'vite (web-app)', pid: 48219, bind: '127.0.0.1' },
  { port: ':5432', process: 'postgres', pid: 19204, bind: '127.0.0.1' },
  { port: ':6379', process: 'redis-server', pid: 19311, bind: '127.0.0.1' },
  { port: ':8080', process: 'go-api-server', pid: 51092, bind: '0.0.0.0' },
]

const DEMO_QUOTAS: Array<{
  id: AiLogoId
  name: string
  percent: number
  window: string
  reset: string
}> = [
  { id: 'claude', name: 'Claude Code', percent: 68, window: '5h session', reset: '2h 14m' },
  { id: 'codex', name: 'Codex CLI', percent: 42, window: 'Weekly', reset: '3d 6h' },
  { id: 'cursor', name: 'Cursor Pro', percent: 81, window: 'Monthly', reset: '9d' },
  { id: 'copilot', name: 'GitHub Copilot', percent: 24, window: 'Monthly', reset: '18d' },
]

export function FeatureShowcase({ theme, activeTab, onTabChange }: FeatureShowcaseProps) {
  const [chargeLimitEnabled, setChargeLimitEnabled] = useState(true)
  const [chargeLimit, setChargeLimit] = useState(80)
  const [toppingUp, setToppingUp] = useState(false)
  const [portQuery, setPortQuery] = useState('')
  const [stoppedPorts, setStoppedPorts] = useState<string[]>([])
  const [lightboxTab, setLightboxTab] = useState<FeatureTabId | null>(null)
  const [lightboxOpen, setLightboxOpen] = useState(false)
  const openLightbox = (id: FeatureTabId) => {
    setLightboxTab(id)
    setLightboxOpen(true)
  }

  const tabs: Array<{
    id: FeatureTabId
    label: string
    pill: string
    title: string
    desc: string
    bullets: [string, string, string]
    shot: (t: ColorScheme) => string
    isPopover?: boolean
  }> = [
    {
      id: 'menubar',
      label: m.tabMenubarLabel(),
      pill: m.tabMenubarPill(),
      title: m.tabMenubarTitle(),
      desc: m.tabMenubarDesc(),
      bullets: [m.tabMenubarBullet1(), m.tabMenubarBullet2(), m.tabMenubarBullet3()],
      shot: (t) => `/screenshots/popovers/popover-overview-${t}.webp`,
      isPopover: true,
    },
    {
      id: 'cpu',
      label: m.tabCpuLabel(),
      pill: m.tabCpuPill(),
      title: m.tabCpuTitle(),
      desc: m.tabCpuDesc(),
      bullets: [m.tabCpuBullet1(), m.tabCpuBullet2(), m.tabCpuBullet3()],
      shot: (t) => `/screenshots/cpu-${t}.webp`,
    },
    {
      id: 'battery',
      label: m.tabBatteryLabel(),
      pill: m.tabBatteryPill(),
      title: m.tabBatteryTitle(),
      desc: m.tabBatteryDesc(),
      bullets: [m.tabBatteryBullet1(), m.tabBatteryBullet2(), m.tabBatteryBullet3()],
      shot: (t) => `/screenshots/battery-${t}.webp`,
    },
    {
      id: 'ports',
      label: m.tabPortsLabel(),
      pill: m.tabPortsPill(),
      title: m.tabPortsTitle(),
      desc: m.tabPortsDesc(),
      bullets: [m.tabPortsBullet1(), m.tabPortsBullet2(), m.tabPortsBullet3()],
      shot: (t) => `/screenshots/popovers/popover-ports-${t}.webp`,
      isPopover: true,
    },
    {
      id: 'ai',
      label: m.tabAiLabel(),
      pill: m.tabAiPill(),
      title: m.tabAiTitle(),
      desc: m.tabAiDesc(),
      bullets: [m.tabAiBullet1(), m.tabAiBullet2(), m.tabAiBullet3()],
      shot: (t) => `/screenshots/ai-usage-${t}.webp`,
    },
    {
      id: 'sensors',
      label: m.tabSensorsLabel(),
      pill: m.tabSensorsPill(),
      title: m.tabSensorsTitle(),
      desc: m.tabSensorsDesc(),
      bullets: [m.tabSensorsBullet1(), m.tabSensorsBullet2(), m.tabSensorsBullet3()],
      shot: (t) => `/screenshots/sensors-${t}.webp`,
    },
  ]

  const filteredPorts = DEMO_PORTS.filter((item) => {
    const q = portQuery.trim().toLowerCase()
    if (!q) return true
    return (
      item.port.includes(q) ||
      item.process.toLowerCase().includes(q) ||
      String(item.pid).includes(q)
    )
  })

  const togglePortStop = (port: string) => {
    setStoppedPorts((prev) =>
      prev.includes(port) ? prev.filter((p) => p !== port) : [...prev, port],
    )
  }

  const renderStage = (tabId: FeatureTabId) => {
    switch (tabId) {
      case 'menubar':
        return (
          <div className="workflow-stage">
            <button
              type="button"
              className="stage-shot-card stage-shot-popover"
              onClick={() => openLightbox('menubar')}
              aria-label={m.workflowsViewScreenshot()}
            >
              <img
                src={`/screenshots/popovers/popover-overview-${theme}.webp`}
                alt={m.tabMenubarTitle()}
                width={736}
                height={1296}
                loading="lazy"
              />
            </button>
          </div>
        )

      case 'cpu':
        return (
          <div className="workflow-stage">
            <button
              type="button"
              className="stage-shot-card"
              onClick={() => openLightbox('cpu')}
              aria-label={m.workflowsViewScreenshot()}
            >
              <img
                src={`/screenshots/panels/cpu-${theme}.webp`}
                alt={m.tabCpuTitle()}
                width={1616}
                height={1400}
                loading="lazy"
              />
            </button>
          </div>
        )

      case 'battery':
        return (
          <div className="workflow-stage">
            <div className="stage-widget">
              <div className="stage-battery-header">
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <BatteryCharging size={18} color="var(--monny-green)" aria-hidden="true" />
                    <strong style={{ fontSize: '0.94rem' }}>{m.tabBatteryControlTitle()}</strong>
                  </div>
                  <p
                    style={{
                      fontSize: '0.78rem',
                      color: 'var(--monny-text-secondary)',
                      marginTop: '0.2rem',
                    }}
                  >
                    {m.tabBatteryControlDesc()}
                  </p>
                </div>

                <Switch
                  checked={chargeLimitEnabled && !toppingUp}
                  onCheckedChange={(details) => {
                    setToppingUp(false)
                    setChargeLimitEnabled(details.checked)
                  }}
                >
                  <SwitchHiddenInput />
                  <SwitchControl>
                    <SwitchThumb />
                  </SwitchControl>
                </Switch>
              </div>

              <div className="stage-widget-row">
                <span className="stage-battery-big mono">
                  {chargeLimitEnabled && !toppingUp ? `${chargeLimit}%` : '100%'}
                </span>
                <span
                  className="pill pill-green"
                  style={{ textTransform: 'none', letterSpacing: 0 }}
                >
                  {chargeLimitEnabled && !toppingUp
                    ? m.tabBatteryStatusActive({ limit: String(chargeLimit) })
                    : m.tabBatteryStatusFull()}
                </span>
              </div>

              <div className="stage-slider-wrap">
                <Slider
                  min={80}
                  max={100}
                  step={5}
                  value={[chargeLimit]}
                  disabled={!chargeLimitEnabled || toppingUp}
                  onValueChange={(details) => {
                    const next = details.value[0]
                    if (typeof next === 'number') setChargeLimit(next)
                  }}
                  aria-label={[m.tabBatteryControlTitle()]}
                >
                  <SliderControl>
                    <SliderTrack>
                      <SliderRange />
                    </SliderTrack>
                    <SliderThumbs />
                  </SliderControl>
                  <SliderMarkerGroup>
                    <SliderMarker value={80}>80%</SliderMarker>
                    <SliderMarker value={85}>85%</SliderMarker>
                    <SliderMarker value={90}>90%</SliderMarker>
                    <SliderMarker value={95}>95%</SliderMarker>
                    <SliderMarker value={100}>100%</SliderMarker>
                  </SliderMarkerGroup>
                </Slider>
              </div>

              <div
                className="stage-widget-row"
                style={{ paddingTop: '0.5rem', borderTop: '1px solid var(--monny-border)' }}
              >
                <span
                  className="mono"
                  style={{ fontSize: '0.75rem', color: 'var(--monny-text-muted)' }}
                >
                  {m.tabBatteryHealth()}
                </span>
                <button
                  type="button"
                  className="btn-monny-outline"
                  style={{ height: '30px', fontSize: '0.76rem' }}
                  onClick={() => setToppingUp((v) => !v)}
                >
                  <Zap size={13} aria-hidden="true" />
                  <span>{toppingUp ? m.tabBatteryTopUpActive() : m.tabBatteryTopUp()}</span>
                </button>
              </div>
            </div>

            <button
              type="button"
              className="stage-shot-card"
              onClick={() => openLightbox('battery')}
              aria-label={m.workflowsViewScreenshot()}
            >
              <img
                src={`/screenshots/panels/battery-${theme}.webp`}
                alt={m.tabBatteryTitle()}
                width={1616}
                height={1400}
                loading="lazy"
                style={{ maxHeight: '215px', objectFit: 'cover', objectPosition: 'top left' }}
              />
            </button>
          </div>
        )

      case 'ports':
        return (
          <div className="workflow-stage">
            <div className="stage-widget">
              <div className="stage-port-search">
                <Search size={14} color="var(--monny-text-muted)" aria-hidden="true" />
                <input
                  type="text"
                  value={portQuery}
                  onChange={(e) => setPortQuery(e.target.value)}
                  placeholder={m.tabPortsPlaceholder()}
                  aria-label={m.tabPortsPlaceholder()}
                />
                <Kbd>⌘F</Kbd>
              </div>

              {filteredPorts.map((item) => {
                const isStopped = stoppedPorts.includes(item.port)
                return (
                  <div
                    key={item.port}
                    className={`port-row ${isStopped ? 'port-row-stopped' : ''}`}
                  >
                    <span className="port-badge">{item.port}</span>
                    <span className="port-proc">
                      {item.process}{' '}
                      <span
                        className="mono"
                        style={{
                          fontWeight: 400,
                          color: 'var(--monny-text-muted)',
                          fontSize: '0.72rem',
                        }}
                      >
                        #{item.pid}
                      </span>
                    </span>
                    <span className="port-bind">{item.bind}</span>
                    <button
                      type="button"
                      className="port-action-btn"
                      onClick={() => togglePortStop(item.port)}
                    >
                      {isStopped ? m.tabPortsStopped() : m.tabPortsKill()}
                    </button>
                  </div>
                )
              })}

              {stoppedPorts.length > 0 ? (
                <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                  <button
                    type="button"
                    className="btn-monny-outline"
                    style={{ height: '28px', fontSize: '0.74rem' }}
                    onClick={() => setStoppedPorts([])}
                  >
                    <RotateCcw size={12} aria-hidden="true" />
                    <span>{m.tabPortsRestore()}</span>
                  </button>
                </div>
              ) : null}
            </div>
          </div>
        )

      case 'ai':
        return (
          <div className="workflow-stage">
            <div className="stage-widget">
              {DEMO_QUOTAS.map((tool) => (
                <div key={tool.id} className="ai-quota-row">
                  <div className="ai-quota-head">
                    <span className="ai-quota-name">
                      <AiLogo id={tool.id} alt={tool.name} theme={theme} size={16} />
                      <span>{tool.name}</span>
                    </span>
                    <span className="ai-quota-meta mono">
                      <span>{m.tabAiResetIn({ time: tool.reset })}</span>
                      <strong style={{ color: 'var(--monny-text)' }}>{tool.percent}%</strong>
                    </span>
                  </div>
                  <ProgressLinear value={tool.percent} min={0} max={100} aria-label={tool.name}>
                    <ProgressLinearTrack>
                      <ProgressLinearRange />
                    </ProgressLinearTrack>
                  </ProgressLinear>
                </div>
              ))}
            </div>
          </div>
        )

      case 'sensors':
        return (
          <div className="workflow-stage">
            <button
              type="button"
              className="stage-shot-card"
              onClick={() => openLightbox('sensors')}
              aria-label={m.workflowsViewScreenshot()}
            >
              <img
                src={`/screenshots/panels/sensors-${theme}.webp`}
                alt={m.tabSensorsTitle()}
                width={1616}
                height={1400}
                loading="lazy"
              />
            </button>
          </div>
        )
    }
  }

  const activeLightbox = lightboxTab ? (tabs.find((t) => t.id === lightboxTab) ?? null) : null

  return (
    <section id="features" className="workflows-section" data-reveal>
      <div className="container">
        <div className="section-header">
          <span className="eyebrow-label">{m.featuresEyebrow()}</span>
          <h2 className="section-title">{m.featuresTitle()}</h2>
          <p className="section-subtitle">{m.featuresSubtitle()}</p>
        </div>

        <Tabs
          value={activeTab}
          onValueChange={(details) => onTabChange(details.value as FeatureTabId)}
        >
          <TabsList className="workflow-tabs-list">
            {tabs.map((tab) => (
              <TabsTrigger key={tab.id} value={tab.id} className="workflow-tab-trigger">
                {tab.label}
              </TabsTrigger>
            ))}
          </TabsList>

          {tabs.map((tab) => (
            <TabsContent key={tab.id} value={tab.id}>
              <div className="workflow-card">
                <div className="workflow-copy">
                  <span className="pill pill-accent">{tab.pill}</span>
                  <h3>{tab.title}</h3>
                  <p>{tab.desc}</p>
                  <ul className="workflow-bullets">
                    {tab.bullets.map((bullet, idx) => (
                      <li key={idx}>
                        <span className="check-dot" aria-hidden="true">
                          <Check size={12} strokeWidth={2.8} />
                        </span>
                        <span>{bullet}</span>
                      </li>
                    ))}
                  </ul>
                  <button
                    type="button"
                    className="workflow-screen-link"
                    onClick={() => openLightbox(tab.id)}
                  >
                    <ImageIcon size={14} aria-hidden="true" />
                    <span>{m.workflowsViewScreenshot()}</span>
                  </button>
                </div>

                {renderStage(tab.id)}
              </div>
            </TabsContent>
          ))}
        </Tabs>
      </div>

      <Dialog
        open={lightboxOpen}
        onOpenChange={(details) => {
          setLightboxOpen(details.open)
        }}
      >
        <DialogBackdrop />
        <DialogPositioner>
          <DialogContent
            className={`lightbox-content ${activeLightbox?.isPopover ? 'lightbox-content-popover' : ''}`}
          >
            <DialogHeader className="lightbox-header">
              <DialogTitle>
                {m.workflowsRealScreen()} · {activeLightbox?.label ?? ''}
              </DialogTitle>
              <DialogCloseIcon />
            </DialogHeader>
            <DialogBody
              className={`lightbox-body ${activeLightbox?.isPopover ? 'lightbox-body-popover' : ''}`}
            >
              {activeLightbox ? (
                <img src={activeLightbox.shot(theme)} alt={activeLightbox.title} />
              ) : null}
            </DialogBody>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </section>
  )
}
