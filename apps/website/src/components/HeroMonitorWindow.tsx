import {
  Activity,
  Asterisk,
  BatteryMedium,
  Cpu,
  Globe,
  HardDrive,
  LayoutDashboard,
  MemoryStick,
  PanelTop,
  Search,
  Settings,
  Thermometer,
} from 'lucide-react'
import type { ReactNode } from 'react'
import { useCallback, useRef, useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

interface HeroMonitorWindowProps {
  theme: ColorScheme
  onToggleTheme?: () => void
}

type HeroMode = 'dashboard' | 'menubar'

type MonnyPanelId =
  | 'overview'
  | 'cpu'
  | 'memory'
  | 'disk'
  | 'network'
  | 'battery'
  | 'sensors'
  | 'ai-usage'
  | 'settings'

type PopoverId = 'overview' | 'ports' | 'battery' | 'ai'

interface SidebarItem {
  id: MonnyPanelId
  label: string
  badgeBg?: string
  icon: ReactNode
}

const MONITOR_ITEMS: SidebarItem[] = [
  {
    id: 'overview',
    label: 'Overview',
    badgeBg: '#2c2c30',
    icon: <Activity size={13} strokeWidth={2.2} />,
  },
  {
    id: 'cpu',
    label: 'CPU',
    badgeBg: '#7c5cff',
    icon: <Cpu size={13} strokeWidth={2.1} />,
  },
  {
    id: 'memory',
    label: 'Memory',
    badgeBg: '#14b8a6',
    icon: <MemoryStick size={13} strokeWidth={2.1} />,
  },
  {
    id: 'disk',
    label: 'Disk',
    badgeBg: '#f59e0b',
    icon: <HardDrive size={13} strokeWidth={2.1} />,
  },
  {
    id: 'network',
    label: 'Network',
    badgeBg: '#3b82f6',
    icon: <Globe size={13} strokeWidth={2.1} />,
  },
  {
    id: 'battery',
    label: 'Battery',
    badgeBg: '#22c55e',
    icon: <BatteryMedium size={14} strokeWidth={2.2} />,
  },
  {
    id: 'sensors',
    label: 'Sensors',
    badgeBg: '#f43f5e',
    icon: <Thermometer size={13} strokeWidth={2.2} />,
  },
  {
    id: 'ai-usage',
    label: 'AI Usage',
    badgeBg: '#2c2c30',
    icon: <Asterisk size={14} strokeWidth={2.4} />,
  },
]

const SETTINGS_ITEM: SidebarItem = {
  id: 'settings',
  label: 'Settings',
  icon: <Settings size={15} strokeWidth={1.85} />,
}

const ALL_ITEMS: SidebarItem[] = [...MONITOR_ITEMS, SETTINGS_ITEM]

function panelSrc(id: MonnyPanelId, theme: ColorScheme): string {
  return `/screenshots/panels/${id}-${theme}.webp`
}

function popoverSrc(id: PopoverId, theme: ColorScheme): string {
  return `/screenshots/popovers/popover-${id}-${theme}.webp`
}

export function HeroMonitorWindow({ theme }: HeroMonitorWindowProps) {
  const [mode, setMode] = useState<HeroMode>('dashboard')
  const [selected, setSelected] = useState<MonnyPanelId>('overview')
  const [displayed, setDisplayed] = useState<MonnyPanelId>('overview')
  const [popoverId, setPopoverId] = useState<PopoverId>('overview')
  const [displayedPopover, setDisplayedPopover] = useState<PopoverId>('overview')
  const preloaded = useRef(new Set<string>())
  const pendingPanel = useRef<MonnyPanelId>('overview')
  const pendingPopover = useRef<PopoverId>('overview')

  const preloadSrc = useCallback((src: string) => {
    if (typeof window === 'undefined' || preloaded.current.has(src)) return
    const img = new window.Image()
    img.decoding = 'async'
    img.onload = () => preloaded.current.add(src)
    img.src = src
  }, [])

  const handleSelectPanel = useCallback(
    (id: MonnyPanelId) => {
      setSelected(id)
      pendingPanel.current = id
      if (typeof window === 'undefined') {
        setDisplayed(id)
        return
      }
      const src = panelSrc(id, theme)
      if (preloaded.current.has(src)) {
        setDisplayed(id)
        return
      }
      const img = new window.Image()
      img.onload = () => {
        preloaded.current.add(src)
        if (pendingPanel.current === id) setDisplayed(id)
      }
      img.onerror = () => {
        if (pendingPanel.current === id) setDisplayed(id)
      }
      img.src = src
    },
    [theme],
  )

  const handleSelectPopover = useCallback(
    (id: PopoverId) => {
      setPopoverId(id)
      pendingPopover.current = id
      if (typeof window === 'undefined') {
        setDisplayedPopover(id)
        return
      }
      const src = popoverSrc(id, theme)
      if (preloaded.current.has(src)) {
        setDisplayedPopover(id)
        return
      }
      const img = new window.Image()
      img.onload = () => {
        preloaded.current.add(src)
        if (pendingPopover.current === id) setDisplayedPopover(id)
      }
      img.onerror = () => {
        if (pendingPopover.current === id) setDisplayedPopover(id)
      }
      img.src = src
    },
    [theme],
  )

  const popoverTabs: Array<{ id: PopoverId; label: string; icon: ReactNode }> = [
    { id: 'overview', label: m.heroPopoverOverview(), icon: <Activity size={14} /> },
    { id: 'ports', label: m.heroPopoverPorts(), icon: <Search size={14} /> },
    { id: 'battery', label: m.heroPopoverBattery(), icon: <BatteryMedium size={15} /> },
    { id: 'ai', label: m.heroPopoverAi(), icon: <Asterisk size={14} /> },
  ]

  const activeLabel = ALL_ITEMS.find((item) => item.id === selected)?.label ?? 'Overview'
  const activePopoverLabel =
    popoverTabs.find((item) => item.id === popoverId)?.label ?? m.heroPopoverOverview()

  return (
    <>
      <div className="hm-desktop-wrap" data-theme={theme}>
        <div className="hm-menubar-bar">
          <div className="hm-mode-tabs" role="tablist" aria-label="Monny preview mode">
            <button
              type="button"
              role="tab"
              aria-selected={mode === 'dashboard'}
              className={`hm-mode-btn ${mode === 'dashboard' ? 'is-active' : ''}`}
              onClick={() => setMode('dashboard')}
            >
              <LayoutDashboard size={13} aria-hidden="true" />
              <span>{m.heroModeDashboard()}</span>
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={mode === 'menubar'}
              className={`hm-mode-btn ${mode === 'menubar' ? 'is-active' : ''}`}
              onMouseEnter={() => preloadSrc(popoverSrc(popoverId, theme))}
              onFocus={() => preloadSrc(popoverSrc(popoverId, theme))}
              onClick={() => setMode('menubar')}
            >
              <PanelTop size={13} aria-hidden="true" />
              <span>{m.heroModeMenubar()}</span>
              <kbd className="hm-kbd">⌥⌘M</kbd>
            </button>
          </div>

          <button
            type="button"
            className={`hm-status-item ${mode === 'menubar' ? 'is-active' : ''}`}
            onMouseEnter={() => preloadSrc(popoverSrc(popoverId, theme))}
            onClick={() => setMode((prev) => (prev === 'menubar' ? 'dashboard' : 'menubar'))}
            aria-pressed={mode === 'menubar'}
            aria-label={m.heroModeMenubar()}
          >
            <span className="hm-status-dot" aria-hidden="true" />
            <span className="hm-status-metric">
              <Cpu size={12} aria-hidden="true" />
              <span>14%</span>
            </span>
            <span className="hm-status-sep" aria-hidden="true" />
            <span className="hm-status-metric">
              <Thermometer size={12} aria-hidden="true" />
              <span>49°C</span>
            </span>
            <span className="hm-status-sep" aria-hidden="true" />
            <span className="hm-status-metric">
              <BatteryMedium size={13} aria-hidden="true" />
              <span>80%</span>
            </span>
          </button>
        </div>

        <div className="hero-monny-shell" data-theme={theme}>
          {mode === 'dashboard' ? (
            <div className="hm-shell-inner">
              <div className="hm-sidebar-col">
                <aside className="hm-sidebar" aria-label="Monny app sections">
                  <div className="hm-traffic-lights" aria-hidden="true">
                    <span className="hm-tl hm-tl-red" />
                    <span className="hm-tl hm-tl-yellow" />
                    <span className="hm-tl hm-tl-green" />
                  </div>

                  <div className="hm-section-label">Monitor</div>

                  <nav className="hm-nav-list" aria-label="Monitor sections">
                    {MONITOR_ITEMS.map((item) => {
                      const isActive = item.id === selected
                      return (
                        <button
                          key={item.id}
                          type="button"
                          className={`hm-nav-item ${isActive ? 'is-active' : ''}`}
                          aria-current={isActive ? 'page' : undefined}
                          onMouseEnter={() => preloadSrc(panelSrc(item.id, theme))}
                          onFocus={() => preloadSrc(panelSrc(item.id, theme))}
                          onClick={() => handleSelectPanel(item.id)}
                        >
                          <span
                            className="hm-nav-badge-ico"
                            style={{ backgroundColor: item.badgeBg }}
                            aria-hidden="true"
                          >
                            {item.icon}
                          </span>
                          <span className="hm-nav-label">{item.label}</span>
                        </button>
                      )
                    })}
                  </nav>

                  <div className="hm-sidebar-footer">
                    <button
                      type="button"
                      className={`hm-nav-item hm-nav-settings ${selected === 'settings' ? 'is-active' : ''}`}
                      aria-current={selected === 'settings' ? 'page' : undefined}
                      onMouseEnter={() => preloadSrc(panelSrc('settings', theme))}
                      onFocus={() => preloadSrc(panelSrc('settings', theme))}
                      onClick={() => handleSelectPanel('settings')}
                    >
                      <span className="hm-settings-ico" aria-hidden="true">
                        {SETTINGS_ITEM.icon}
                      </span>
                      <span className="hm-nav-label">{SETTINGS_ITEM.label}</span>
                    </button>
                  </div>
                </aside>
              </div>

              <div className="hm-stage">
                <img
                  src={panelSrc(displayed, theme)}
                  alt={`Monny ${activeLabel} screen`}
                  className="hm-stage-img"
                  width={1612}
                  height={1392}
                  decoding="sync"
                />
              </div>
            </div>
          ) : (
            <div className="hm-popover-stage">
              <div className="hm-popover-info">
                <span className="hm-popover-eyebrow">{m.heroPopoverEyebrow()}</span>
                <p className="hm-popover-lead">{m.heroPopoverLead()}</p>

                <div className="hm-popover-pills" role="tablist" aria-label="Menu bar popover tabs">
                  {popoverTabs.map((tab) => {
                    const isActive = tab.id === popoverId
                    return (
                      <button
                        key={tab.id}
                        type="button"
                        role="tab"
                        aria-selected={isActive}
                        className={`hm-popover-pill ${isActive ? 'is-active' : ''}`}
                        onMouseEnter={() => preloadSrc(popoverSrc(tab.id, theme))}
                        onFocus={() => preloadSrc(popoverSrc(tab.id, theme))}
                        onClick={() => handleSelectPopover(tab.id)}
                      >
                        <span className="hm-popover-pill-ico" aria-hidden="true">
                          {tab.icon}
                        </span>
                        <span>{tab.label}</span>
                      </button>
                    )
                  })}
                </div>

                <button
                  type="button"
                  className="hm-popover-back"
                  onClick={() => setMode('dashboard')}
                >
                  <LayoutDashboard size={14} aria-hidden="true" />
                  <span>{m.heroPopoverOpenDashboard()}</span>
                </button>
              </div>

              <div className="hm-popover-preview-col">
                <div className="hm-popover-frame">
                  <img
                    src={popoverSrc(displayedPopover, theme)}
                    alt={`Monny menu bar popover: ${activePopoverLabel}`}
                    width={712}
                    height={1264}
                    decoding="sync"
                  />
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Mobile crisp real Popover showcase matching Sketch W03 */}
      <div className="hero-mobile-popover">
        <div className="hero-mobile-popover-tabs" role="tablist" aria-label="Menu bar views">
          {popoverTabs.map((tab) => (
            <button
              key={tab.id}
              type="button"
              role="tab"
              aria-selected={popoverId === tab.id}
              className={`hero-mobile-popover-tab ${popoverId === tab.id ? 'is-active' : ''}`}
              onClick={() => handleSelectPopover(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </div>
        <div className="hero-mobile-popover-frame">
          <img
            src={popoverSrc(displayedPopover, theme)}
            alt={`Monny menu bar popover: ${activePopoverLabel}`}
            width={712}
            height={1264}
          />
        </div>
      </div>
    </>
  )
}
