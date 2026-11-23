import { ArrowUpRight, Download, Star } from 'lucide-react'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseAssets } from '@/integrations/releases'

interface FinalCtaProps {
  release: ReleaseAssets
}

export function FinalCta({ release }: FinalCtaProps) {
  return (
    <section className="final-cta-section" data-reveal>
      <div className="container">
        <div className="final-cta-card">
          <img
            src="/app-icon.png"
            alt={site.name}
            width={60}
            height={60}
            className="final-cta-icon"
          />
          <h2>{m.ctaTitle()}</h2>
          <p>{m.ctaSubtitle()}</p>
          <div className="final-cta-actions">
            <a href={release.dmgUrl} className="btn-monny-primary">
              <Download size={16} aria-hidden="true" />
              <span>{m.ctaDownload({ version: release.version })}</span>
            </a>
            <a
              href={site.repository}
              target="_blank"
              rel="noreferrer"
              className="btn-monny-outline"
              style={{ height: '44px', padding: '0 1.2rem' }}
            >
              <Star size={15} aria-hidden="true" />
              <span>{m.ctaGithub()}</span>
            </a>
          </div>
        </div>

        <div className="suite-band">
          <p className="suite-eyebrow">{m.suiteEyebrow()}</p>
          <div className="suite-grid">
            <a href={site.suite.hearth} target="_blank" rel="noreferrer" className="suite-card">
              <img src="/suite/hearth.png" alt="Hearth" width={48} height={48} loading="lazy" />
              <div className="suite-card-body">
                <strong>Hearth</strong>
                <p>{m.suiteHearthDesc()}</p>
              </div>
              <span className="suite-card-arrow">
                {m.suiteExplore()}
                <ArrowUpRight size={14} aria-hidden="true" />
              </span>
            </a>

            <a href={site.suite.rebind} target="_blank" rel="noreferrer" className="suite-card">
              <img src="/suite/rebind.png" alt="Rebind" width={48} height={48} loading="lazy" />
              <div className="suite-card-body">
                <strong>Rebind</strong>
                <p>{m.suiteRebindDesc()}</p>
              </div>
              <span className="suite-card-arrow">
                {m.suiteExplore()}
                <ArrowUpRight size={14} aria-hidden="true" />
              </span>
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
