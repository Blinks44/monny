import {
  Activity,
  Asterisk,
  BatteryMedium,
  Cpu,
  Globe,
  HardDrive,
  MemoryStick,
  Settings,
  Thermometer,
} from 'lucide-react'
import type { ReactNode } from 'react'
import { useCallback, useRef, useState } from 'react'
import type { ColorScheme } from '@/lib/theme'

interface HeroMonitorWindowProps {
  theme: ColorScheme
  onToggleTheme?: () => void
}

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

export function HeroMonitorWindow({ theme }: HeroMonitorWindowProps) {
  const [selected, setSelected] = useState<MonnyPanelId>('overview')
  const [displayed, setDisplayed] = useState<MonnyPanelId>('overview')
  const preloaded = useRef(new Set<string>())
  const pending = useRef<MonnyPanelId>('overview')

  const preloadPanel = useCallback(
    (id: MonnyPanelId) => {
      if (typeof window === 'undefined') return
      const src = panelSrc(id, theme)
      if (preloaded.current.has(src)) return
      const img = new window.Image()
      img.decoding = 'async'
      img.onload = () => preloaded.current.add(src)
      img.src = src
    },
    [theme],
  )

  const handleSelect = useCallback(
    (id: MonnyPanelId) => {
      setSelected(id)
      pending.current = id
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
        if (pending.current === id) setDisplayed(id)
      }
      img.onerror = () => {
        if (pending.current === id) setDisplayed(id)
      }
      img.src = src
    },
    [theme],
  )

  const activeLabel = ALL_ITEMS.find((item) => item.id === selected)?.label ?? 'Overview'

  return (
    <>
      <div className="hero-monny-shell" data-theme={theme}>
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
                      onMouseEnter={() => preloadPanel(item.id)}
                      onFocus={() => preloadPanel(item.id)}
                      onClick={() => handleSelect(item.id)}
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
                  onMouseEnter={() => preloadPanel('settings')}
                  onFocus={() => preloadPanel('settings')}
                  onClick={() => handleSelect('settings')}
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
      </div>

      {/* Mobile crisp real Popover showcase matching Sketch W03 */}
      <div className="hero-mobile-popover">
        <div className="hero-mobile-popover-frame">
          <img
            src={`/screenshots/popovers/popover-overview-${theme}.webp`}
            alt="Monny menu bar popover overview"
            width={712}
            height={1264}
          />
        </div>
      </div>
    </>
  )
}
