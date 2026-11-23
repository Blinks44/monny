import {
  Activity,
  BatteryCharging,
  Cpu,
  HardDrive,
  LayoutGrid,
  MemoryStick,
  Moon,
  Network,
  Search,
  Settings,
  Sparkles,
  Sun,
  Thermometer,
} from 'lucide-react'
import type { ReactNode } from 'react'
import { useCallback, useMemo, useRef, useState } from 'react'
import type { ColorScheme } from '@/lib/theme'

interface HeroMonitorWindowProps {
  theme: ColorScheme
  onToggleTheme: () => void
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
  keywords: string
  badge?: string
  badgeTone?: 'accent' | 'good'
  icon: ReactNode
}

interface SidebarSection {
  title?: string
  items: SidebarItem[]
}

const SIDEBAR_SECTIONS: SidebarSection[] = [
  {
    items: [
      {
        id: 'overview',
        label: 'Overview',
        keywords: 'overview summary dashboard mac status',
        icon: <LayoutGrid size={14} strokeWidth={1.9} />,
      },
    ],
  },
  {
    title: 'Hardware',
    items: [
      {
        id: 'cpu',
        label: 'CPU',
        keywords: 'cpu cores efficiency performance history processes',
        badge: '24%',
        icon: <Cpu size={14} strokeWidth={1.9} />,
      },
      {
        id: 'memory',
        label: 'Memory',
        keywords: 'memory ram swap pressure compressed wired',
        badge: '18.4 GB',
        icon: <MemoryStick size={14} strokeWidth={1.9} />,
      },
      {
        id: 'disk',
        label: 'Disk',
        keywords: 'disk ssd apfs smart storage read write',
        badge: '412 GB',
        icon: <HardDrive size={14} strokeWidth={1.9} />,
      },
      {
        id: 'network',
        label: 'Network',
        keywords: 'network ports tcp bandwidth wifi ethernet ip',
        badge: '12 ports',
        icon: <Network size={14} strokeWidth={1.9} />,
      },
      {
        id: 'battery',
        label: 'Battery',
        keywords: 'battery charge limit 80% power cycles adapter health',
        badge: '80%',
        badgeTone: 'good',
        icon: <BatteryCharging size={14} strokeWidth={1.9} />,
      },
      {
        id: 'sensors',
        label: 'Sensors',
        keywords: 'sensors smc temperature die fan rpm watts thermal',
        badge: '46 °C',
        icon: <Thermometer size={14} strokeWidth={1.9} />,
      },
    ],
  },
  {
    title: 'Developer',
    items: [
      {
        id: 'ai-usage',
        label: 'AI Usage',
        keywords: 'ai quotas claude codex cursor copilot gemini windsurf tokens',
        badge: '22 tools',
        badgeTone: 'accent',
        icon: <Sparkles size={14} strokeWidth={1.9} />,
      },
    ],
  },
]

const SETTINGS_ITEM: SidebarItem = {
  id: 'settings',
  label: 'Settings',
  keywords: 'settings preferences menu bar launch login sparkle',
  icon: <Settings size={14} strokeWidth={1.9} />,
}

const ALL_ITEMS: SidebarItem[] = [
  ...SIDEBAR_SECTIONS.flatMap((section) => section.items),
  SETTINGS_ITEM,
]

function panelSrc(id: MonnyPanelId, theme: ColorScheme): string {
  return `/screenshots/panels/${id}-${theme}.webp`
}

export function HeroMonitorWindow({ theme, onToggleTheme }: HeroMonitorWindowProps) {
  const [active, setActive] = useState<MonnyPanelId>('overview')
  const [displayed, setDisplayed] = useState<MonnyPanelId>('overview')
  const [query, setQuery] = useState('')
  const decodedCache = useRef<Map<string, HTMLImageElement>>(new Map())
  const pendingLoads = useRef<Map<string, Promise<void>>>(new Map())
  const wantedId = useRef<MonnyPanelId>('overview')

  const ensureDecoded = useCallback((src: string): Promise<void> => {
    if (decodedCache.current.has(src)) return Promise.resolve()
    const inflight = pendingLoads.current.get(src)
    if (inflight) return inflight

    const img = new Image()
    img.decoding = 'sync'
    img.src = src

    const promise = (
      typeof img.decode === 'function'
        ? img.decode()
        : new Promise<void>((resolve, reject) => {
            img.onload = () => resolve()
            img.onerror = () => reject(new Error(`failed to load ${src}`))
          })
    )
      .then(() => {
        decodedCache.current.set(src, img)
      })
      .catch(() => {
        // Fallback to direct <img> rendering.
      })
      .finally(() => {
        pendingLoads.current.delete(src)
      })

    pendingLoads.current.set(src, promise)
    return promise
  }, [])

  const preloadPanel = useCallback(
    (id: MonnyPanelId) => {
      void ensureDecoded(panelSrc(id, theme))
    },
    [ensureDecoded, theme],
  )

  const selectPanel = useCallback(
    (id: MonnyPanelId) => {
      wantedId.current = id
      setActive(id)
      const src = panelSrc(id, theme)
      if (decodedCache.current.has(src)) {
        setDisplayed(id)
        return
      }
      void ensureDecoded(src).then(() => {
        if (wantedId.current === id) {
          setDisplayed(id)
        }
      })
    },
    [ensureDecoded, theme],
  )

  const filteredSections = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return SIDEBAR_SECTIONS
    return SIDEBAR_SECTIONS.map((section) => ({
      ...section,
      items: section.items.filter(
        (item) => item.label.toLowerCase().includes(q) || item.keywords.toLowerCase().includes(q),
      ),
    })).filter((section) => section.items.length > 0)
  }, [query])

  const activeItem = ALL_ITEMS.find((item) => item.id === active) ?? SETTINGS_ITEM

  return (
    <>
      <div className="hero-monny-shell" data-theme={theme}>
        <aside className="hm-sidebar" aria-label="Monny sections">
          <div className="hm-traffic-lights" aria-hidden="true">
            <span className="hm-tl hm-tl-red" />
            <span className="hm-tl hm-tl-yellow" />
            <span className="hm-tl hm-tl-green" />
          </div>

          <div className="hm-brand">
            <img src="/app-icon.png" alt="" width={24} height={24} className="hm-brand-icon" />
            <div className="hm-brand-text">
              <strong>Monny</strong>
              <span>MacBook Pro · M4 Pro</span>
            </div>
          </div>

          <label className="hm-search">
            <Search size={12} className="hm-search-ico" aria-hidden="true" />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && filteredSections[0]?.items[0]) {
                  selectPanel(filteredSections[0].items[0].id)
                }
              }}
              placeholder="Jump to metric..."
              aria-label="Jump to metric"
            />
          </label>

          <div className="hm-nav-scroll" role="tablist" aria-orientation="vertical">
            {filteredSections.map((section, idx) => (
              <div key={section.title ?? `top-${idx}`}>
                {section.title ? <div className="hm-section-label">{section.title}</div> : null}
                {section.items.map((item) => {
                  const isSelected = active === item.id
                  return (
                    <button
                      key={item.id}
                      type="button"
                      role="tab"
                      aria-selected={isSelected}
                      className={`hm-nav-item ${isSelected ? 'is-active' : ''}`}
                      onMouseEnter={() => preloadPanel(item.id)}
                      onFocus={() => preloadPanel(item.id)}
                      onClick={() => selectPanel(item.id)}
                    >
                      <span className="hm-nav-ico" aria-hidden="true">
                        {item.icon}
                      </span>
                      <span className="hm-nav-label">{item.label}</span>
                      {item.badge ? (
                        <span
                          className={`hm-nav-badge ${
                            item.badgeTone === 'accent'
                              ? 'is-accent'
                              : item.badgeTone === 'good'
                                ? 'is-good'
                                : ''
                          }`}
                        >
                          {item.badge}
                        </span>
                      ) : null}
                    </button>
                  )
                })}
              </div>
            ))}
            {filteredSections.length === 0 ? (
              <div className="hm-nav-empty">No matching view</div>
            ) : null}
          </div>

          <div className="hm-sidebar-footer">
            <button
              type="button"
              role="tab"
              aria-selected={active === 'settings'}
              className={`hm-nav-item ${active === 'settings' ? 'is-active' : ''}`}
              onMouseEnter={() => preloadPanel('settings')}
              onFocus={() => preloadPanel('settings')}
              onClick={() => selectPanel('settings')}
            >
              <span className="hm-nav-ico" aria-hidden="true">
                {SETTINGS_ITEM.icon}
              </span>
              <span className="hm-nav-label">Settings</span>
            </button>

            <div className="hm-status-row">
              <span className="hm-status-left">
                <span className="hm-status-dot" />
                <Activity size={11} aria-hidden="true" />
                <span>1 Hz · ~5 MB</span>
              </span>
              <div className="hm-status-actions">
                <button
                  type="button"
                  className="hm-icon-btn"
                  onClick={onToggleTheme}
                  aria-label="Toggle theme"
                  title="Toggle theme"
                >
                  {theme === 'dark' ? <Sun size={12} /> : <Moon size={12} />}
                </button>
              </div>
            </div>
          </div>
        </aside>

        <div className="hm-stage" role="tabpanel" aria-label={activeItem.label}>
          <img
            key={`${displayed}-${theme}`}
            src={panelSrc(displayed, theme)}
            alt={`Monny ${activeItem.label} screen`}
            className="hm-stage-img"
            width={1616}
            height={1400}
            decoding="sync"
          />
        </div>
      </div>

      {/* Mobile crisp real Popover showcase matching Sketch W03 */}
      <div className="hero-mobile-popover">
        <div className="hero-mobile-popover-frame">
          <img
            src={`/screenshots/popovers/popover-overview-${theme}.webp`}
            alt="Monny menu bar popover overview"
            width={720}
            height={1272}
          />
        </div>
      </div>
    </>
  )
}
