import { Link } from '@tanstack/react-router'
import { ArrowRight, ArrowUpRight, Check, Download, Minus } from 'lucide-react'
import { CopyButton } from '@/components/CopyButton'
import { Footer } from '@/components/Footer'
import { Navbar } from '@/components/Navbar'
import type { Locale } from '@/config/locales'
import { site } from '@/config/site'
import { type AlternativeSlug, getAlternativeContent } from '@/content/seo'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import type { ReleaseAssets } from '@/integrations/releases'
import { useRevealObserver } from '@/lib/reveal'
import { useTheme } from '@/lib/theme'

interface AlternativePageProps {
  slug: AlternativeSlug
  release: ReleaseAssets
}

export function AlternativePage({ slug, release }: AlternativePageProps) {
  const locale = getLocale() as Locale
  const content = getAlternativeContent(locale, slug)
  const { theme, toggleTheme } = useTheme()

  useRevealObserver()

  const switcher = [
    {
      slug: 'istat-menus' as const,
      to: '/alternatives/istat-menus/' as const,
      label: m.seoSwitchIstat(),
    },
    {
      slug: 'aldente' as const,
      to: '/alternatives/aldente/' as const,
      label: m.seoSwitchAldente(),
    },
  ]

  const internalRelated = [
    {
      to: '/alternatives/istat-menus/' as const,
      title: m.seoRelatedIstatTitle(),
      description: m.seoRelatedIstatDesc(),
      exclude: slug === 'istat-menus',
    },
    {
      to: '/alternatives/aldente/' as const,
      title: m.seoRelatedAldenteTitle(),
      description: m.seoRelatedAldenteDesc(),
      exclude: slug === 'aldente',
    },
    {
      to: '/guides/ai-coding-quotas/' as const,
      title: m.seoRelatedAiTitle(),
      description: m.seoRelatedAiDesc(),
      exclude: false,
    },
    {
      to: '/guides/port-pid-finder/' as const,
      title: m.seoRelatedPortsTitle(),
      description: m.seoRelatedPortsDesc(),
      exclude: false,
    },
  ].filter((item) => !item.exclude)

  return (
    <>
      <Navbar theme={theme} onToggleTheme={toggleTheme} />
      <main id="top" className="seo-subpage">
        <div className="container">
          <div className="seo-subpage-topbar">
            <nav className="seo-breadcrumbs" aria-label="Breadcrumb">
              <Link to="/">{m.seoBreadcrumbHome()}</Link>
              <span aria-hidden="true">/</span>
              <span>{m.seoBreadcrumbAlternatives()}</span>
              <span aria-hidden="true">/</span>
              <span aria-current="page">{content.breadcrumbLabel}</span>
            </nav>

            <div className="seo-pill-switcher">
              {switcher.map((item) => (
                <Link
                  key={item.slug}
                  to={item.to}
                  className={item.slug === slug ? 'seo-pill seo-pill-active' : 'seo-pill'}
                >
                  {item.label}
                </Link>
              ))}
            </div>
          </div>

          <section className="seo-subpage-hero">
            <h1>{content.headline}</h1>
            <p className="seo-subpage-subtitle">{content.subtitle}</p>

            <div className="seo-hero-actions">
              <a href={release.dmgUrl} className="btn-monny-primary">
                <Download size={16} aria-hidden="true" />
                <span>{m.seoDownloadFree()}</span>
              </a>
              <div className="seo-brew-pill">
                <span className="seo-brew-prompt mono" aria-hidden="true">
                  $
                </span>
                <code className="mono">{site.brewCommand}</code>
                <CopyButton text={site.brewCommand} />
              </div>
            </div>

            <div className="seo-highlights-grid">
              {content.highlights.map((metric) => (
                <div key={metric.value} className="seo-highlight-card">
                  <strong className="mono">{metric.value}</strong>
                  <span>{metric.label}</span>
                </div>
              ))}
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{m.seoComparisonTitle()}</h2>
            <div className="seo-table-card">
              <div className="seo-table-scroll">
                <table className="seo-compare-table">
                  <thead>
                    <tr>
                      <th scope="col">{m.seoColCriterion()}</th>
                      <th scope="col" className="seo-compare-monny-head">
                        {m.seoColMonny()}
                      </th>
                      <th scope="col">{content.competitorColumn}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {content.rows.map((row) => (
                      <tr key={row.criterion}>
                        <th scope="row" className="seo-cell-category">
                          {row.criterion}
                        </th>
                        <td className="seo-compare-monny-cell">
                          <span className="seo-compare-check">
                            <Check size={14} aria-hidden="true" />
                            <span>{row.monny}</span>
                          </span>
                        </td>
                        <td className="seo-compare-other-cell">{row.other}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </section>

          <section className="seo-block">
            <div className="seo-fit-grid">
              <article className="seo-fit-card seo-fit-card-recommended">
                <span className="seo-fit-label seo-fit-label-accent">
                  {content.chooseMonny.label}
                </span>
                <h3>{content.chooseMonny.title}</h3>
                <ul className="seo-check-list">
                  {content.chooseMonny.points.map((point) => (
                    <li key={point}>
                      <Check size={15} className="seo-check-icon" aria-hidden="true" />
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </article>

              <article className="seo-fit-card">
                <span className="seo-fit-label">{content.stickWithOther.label}</span>
                <h3>{content.stickWithOther.title}</h3>
                <ul className="seo-check-list seo-check-list-neutral">
                  {content.stickWithOther.points.map((point) => (
                    <li key={point}>
                      <Minus size={14} className="seo-minus-icon" aria-hidden="true" />
                      <span>{point}</span>
                    </li>
                  ))}
                </ul>
              </article>
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{m.seoSwitchStepsTitle()}</h2>
            <div className="seo-steps-grid seo-steps-grid-3">
              {content.steps.map((step) => (
                <article key={step.step} className="seo-step-card">
                  <span className="seo-step-kicker mono">{step.step}</span>
                  <h3>{step.title}</h3>
                  <p>{step.description}</p>
                </article>
              ))}
            </div>
          </section>

          <section className="seo-block">
            <h2 className="seo-block-title">{m.seoMoreTitle()}</h2>
            <div className="seo-related-grid">
              {internalRelated.map((item) => (
                <Link key={item.to} to={item.to} className="seo-related-card">
                  <div className="seo-related-title-row">
                    <strong>{item.title}</strong>
                    <ArrowRight size={14} aria-hidden="true" />
                  </div>
                  <p>{item.description}</p>
                </Link>
              ))}
              <a
                href={site.suite.hearth}
                target="_blank"
                rel="noreferrer"
                className="seo-related-card"
              >
                <div className="seo-related-title-row">
                  <strong>{m.seoRelatedHearthTitle()}</strong>
                  <ArrowUpRight size={14} aria-hidden="true" />
                </div>
                <p>{m.seoRelatedHearthDesc()}</p>
              </a>
            </div>
          </section>

          <section className="seo-bottom-cta">
            <div className="seo-bottom-cta-copy">
              <h2>{m.seoAltCtaTitle()}</h2>
              <p>{m.seoAltCtaSub()}</p>
            </div>
            <a href={release.dmgUrl} className="btn-monny-primary">
              <Download size={16} aria-hidden="true" />
              <span>{m.seoDownloadFree()}</span>
            </a>
          </section>
        </div>
      </main>
      <Footer release={release} />
    </>
  )
}
