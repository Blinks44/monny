import { Link } from '@tanstack/react-router'
import type { FeatureTabId } from '@/components/FeatureShowcase'
import { site } from '@/config/site'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ReleaseAssets } from '@/integrations/releases'

interface FooterProps {
  release: ReleaseAssets
  onSelectFeature?: (tab: FeatureTabId) => void
}

export function Footer({ release, onSelectFeature }: FooterProps) {
  const jumpToFeature = (tab: FeatureTabId) => {
    onSelectFeature?.(tab)
    const target = document.getElementById('features')
    target?.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <footer className="site-footer">
      <div className="container">
        <div className="footer-grid">
          <div className="footer-brand">
            <Link to="/" className="brand-link">
              <img
                src="/app-icon.png"
                alt={site.name}
                width={26}
                height={26}
                className="brand-icon"
              />
              <span>{site.name}</span>
            </Link>
            <p>{m.footerTagline()}</p>
          </div>

          <div className="footer-col">
            <h4>{m.footerColProduct()}</h4>
            <ul>
              {onSelectFeature ? (
                <>
                  <li>
                    <button type="button" onClick={() => jumpToFeature('menubar')}>
                      {m.tabMenubarLabel()}
                    </button>
                  </li>
                  <li>
                    <button type="button" onClick={() => jumpToFeature('battery')}>
                      {m.tabBatteryLabel()}
                    </button>
                  </li>
                  <li>
                    <button type="button" onClick={() => jumpToFeature('ports')}>
                      {m.tabPortsLabel()}
                    </button>
                  </li>
                  <li>
                    <button type="button" onClick={() => jumpToFeature('ai')}>
                      {m.tabAiLabel()}
                    </button>
                  </li>
                </>
              ) : (
                <>
                  <li>
                    <Link to="/" hash="features">
                      {m.tabMenubarLabel()}
                    </Link>
                  </li>
                  <li>
                    <Link to="/" hash="features">
                      {m.tabBatteryLabel()}
                    </Link>
                  </li>
                  <li>
                    <Link to="/" hash="features">
                      {m.tabPortsLabel()}
                    </Link>
                  </li>
                  <li>
                    <Link to="/" hash="features">
                      {m.tabAiLabel()}
                    </Link>
                  </li>
                </>
              )}
            </ul>
          </div>

          <div className="footer-col">
            <h4>{m.footerColComparisons()}</h4>
            <ul>
              <li>
                <Link to="/alternatives/istat-menus/">{m.footerCompareIstat()}</Link>
              </li>
              <li>
                <Link to="/alternatives/aldente/">{m.footerCompareAldente()}</Link>
              </li>
              <li>
                <Link to="/guides/ai-coding-quotas/">{m.footerGuideAi()}</Link>
              </li>
              <li>
                <Link to="/guides/port-pid-finder/">{m.footerGuidePorts()}</Link>
              </li>
            </ul>
          </div>

          <div className="footer-col">
            <h4>{m.footerColResources()}</h4>
            <ul>
              <li>
                <a href={site.docs} target="_blank" rel="noreferrer">
                  {m.footerDocs()}
                </a>
              </li>
              <li>
                <a href={release.releaseUrl} target="_blank" rel="noreferrer">
                  {m.footerReleases()} (v{release.version})
                </a>
              </li>
              <li>
                <a href={site.changelog} target="_blank" rel="noreferrer">
                  {m.footerChangelog()}
                </a>
              </li>
              <li>
                <a href={site.security} target="_blank" rel="noreferrer">
                  {m.footerSecurity()}
                </a>
              </li>
            </ul>
          </div>

          <div className="footer-col">
            <h4>{m.footerColSuite()}</h4>
            <ul>
              <li>
                <a href={site.suite.hearth} target="_blank" rel="noreferrer">
                  Hearth
                </a>
              </li>
              <li>
                <a href={site.suite.rebind} target="_blank" rel="noreferrer">
                  Rebind
                </a>
              </li>
            </ul>
          </div>

          <div className="footer-col">
            <h4>{m.footerColCommunity()}</h4>
            <ul>
              <li>
                <a href={site.repository} target="_blank" rel="noreferrer">
                  GitHub
                </a>
              </li>
              <li>
                <a href={site.discussions} target="_blank" rel="noreferrer">
                  {m.footerDiscussions()}
                </a>
              </li>
              <li>
                <a href={site.issues} target="_blank" rel="noreferrer">
                  {m.footerIssues()}
                </a>
              </li>
              <li>
                <a href={site.contributing} target="_blank" rel="noreferrer">
                  {m.footerContributing()}
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <a href={site.license} target="_blank" rel="noreferrer">
            {m.footerLicense()}
          </a>
          <a href={site.author.x} target="_blank" rel="noreferrer">
            {m.footerMadeBy({ author: site.author.name })}
          </a>
        </div>
      </div>
    </footer>
  )
}
