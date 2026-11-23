import { Download, ExternalLink, ShieldCheck, Terminal } from 'lucide-react'
import { CopyButton } from '@/components/CopyButton'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseAssets } from '@/integrations/releases'

interface InstallSectionProps {
  release: ReleaseAssets
}

export function InstallSection({ release }: InstallSectionProps) {
  return (
    <section id="install" className="install-section" data-reveal>
      <div className="container">
        <div className="section-header">
          <span className="eyebrow-label">{m.installEyebrow()}</span>
          <h2 className="section-title">{m.installTitle()}</h2>
          <p className="section-subtitle">{m.installSubtitle()}</p>
        </div>

        <div className="install-grid">
          <div className="install-card">
            <span className="install-card-icon" aria-hidden="true">
              <Download size={20} />
            </span>
            <h3>{m.installDmgTitle()}</h3>
            <p>{m.installDmgDesc()}</p>
            <div>
              <a href={release.dmgUrl} className="btn-monny-primary">
                <Download size={16} aria-hidden="true" />
                <span>{m.installDmgBtn({ version: release.version })}</span>
              </a>
            </div>
            <p className="install-meta">{m.installDmgMeta()}</p>
          </div>

          <div className="install-card">
            <span className="install-card-icon" aria-hidden="true">
              <Terminal size={20} />
            </span>
            <h3>{m.installBrewTitle()}</h3>
            <p>{m.installBrewDesc()}</p>
            <div className="install-cmd-box">
              <code>{site.brewCommand}</code>
              <CopyButton text={site.brewCommand} />
            </div>
            <p className="install-meta">{m.installBrewNote()}</p>
          </div>
        </div>

        <div className="install-trust-bar">
          <div className="install-trust-left">
            <ShieldCheck size={20} color="var(--monny-green)" aria-hidden="true" />
            <div>
              <strong>{m.installTrustTitle()}</strong>
              <span>{m.installTrustDesc()}</span>
            </div>
          </div>

          <div className="install-trust-links">
            <a
              href={release.checksumsUrl}
              target="_blank"
              rel="noreferrer"
              className="btn-monny-outline"
            >
              <span>{m.installTrustChecksums()}</span>
              <ExternalLink size={13} aria-hidden="true" />
            </a>
            <a
              href={release.releaseUrl}
              target="_blank"
              rel="noreferrer"
              className="btn-monny-outline"
            >
              <span>{m.installTrustReleases()}</span>
              <ExternalLink size={13} aria-hidden="true" />
            </a>
          </div>
        </div>
      </div>
    </section>
  )
}
