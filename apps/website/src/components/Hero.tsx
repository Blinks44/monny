import { Badge, BadgeDot, BadgeLabel } from '@moduix/react/badge'
import { Download } from 'lucide-react'
import { CopyButton } from '@/components/CopyButton'
import { HeroMonitorWindow } from '@/components/HeroMonitorWindow'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseAssets } from '@/integrations/releases'
import type { ColorScheme } from '@/lib/theme'

interface HeroProps {
  release: ReleaseAssets
  theme: ColorScheme
  onToggleTheme: () => void
}

export function Hero({ release, theme, onToggleTheme }: HeroProps) {
  return (
    <section id="top" className="hero-section">
      <div className="container hero-inner">
        <Badge variant="outline" className="hero-eyebrow-badge">
          <BadgeDot className="hero-eyebrow-dot" />
          <BadgeLabel>{m.heroEyebrow({ version: release.version })}</BadgeLabel>
        </Badge>

        <h1 className="hero-title">
          {m.heroTitleLine1()}
          <span className="hero-title-accent">{m.heroTitleLine2()}</span>
        </h1>

        <p className="hero-subtitle">{m.heroSubtitle()}</p>

        <div className="hero-actions">
          <a href={release.dmgUrl} className="btn-monny-primary">
            <Download size={17} aria-hidden="true" />
            <span>{m.heroPrimaryCta()}</span>
          </a>

          <div className="brew-pill">
            <code>
              <span className="brew-pill-prefix">$</span>
              {site.brewCommand}
            </code>
            <CopyButton text={site.brewCommand} />
          </div>
        </div>

        <p className="hero-meta">{m.heroMeta()}</p>

        <div className="hero-window-wrap">
          <HeroMonitorWindow theme={theme} onToggleTheme={onToggleTheme} />
          <p className="hero-interactive-hint">{m.heroInteractiveHint()}</p>
        </div>
      </div>
    </section>
  )
}
