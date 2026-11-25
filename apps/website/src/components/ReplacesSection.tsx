import { Link } from '@tanstack/react-router'
import { ArrowRight } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'

interface ReplaceRow {
  id: string
  category: string
  tools: string
  monny: string
  cta: string
  to:
    | '/alternatives/istat-menus/'
    | '/alternatives/aldente/'
    | '/guides/ai-coding-quotas/'
    | '/guides/port-pid-finder/'
    | '/'
  hash?: string
}

export function ReplacesSection() {
  const rows: ReplaceRow[] = [
    {
      id: 'menubar',
      category: m.replacesRow1Cat(),
      tools: m.replacesRow1Tools(),
      monny: m.replacesRow1Monny(),
      cta: m.replacesRow1Cta(),
      to: '/alternatives/istat-menus/',
    },
    {
      id: 'battery',
      category: m.replacesRow2Cat(),
      tools: m.replacesRow2Tools(),
      monny: m.replacesRow2Monny(),
      cta: m.replacesRow2Cta(),
      to: '/alternatives/aldente/',
    },
    {
      id: 'ai',
      category: m.replacesRow3Cat(),
      tools: m.replacesRow3Tools(),
      monny: m.replacesRow3Monny(),
      cta: m.replacesRow3Cta(),
      to: '/guides/ai-coding-quotas/',
    },
    {
      id: 'ports',
      category: m.replacesRow4Cat(),
      tools: m.replacesRow4Tools(),
      monny: m.replacesRow4Monny(),
      cta: m.replacesRow4Cta(),
      to: '/guides/port-pid-finder/',
    },
    {
      id: 'thermals',
      category: m.replacesRow5Cat(),
      tools: m.replacesRow5Tools(),
      monny: m.replacesRow5Monny(),
      cta: m.replacesRow5Cta(),
      to: '/',
      hash: 'bento',
    },
  ]

  return (
    <section id="replaces" className="seo-section seo-section-surface" data-reveal>
      <div className="container">
        <div className="section-header">
          <span className="eyebrow-label">{m.replacesEyebrow()}</span>
          <h2 className="section-title">{m.replacesTitle()}</h2>
          <p className="section-subtitle">{m.replacesSubtitle()}</p>
        </div>

        <div className="seo-table-card">
          <div className="seo-table-scroll">
            <table className="seo-replaces-table">
              <thead>
                <tr>
                  <th scope="col">{m.replacesColWorkflow()}</th>
                  <th scope="col">{m.replacesColTools()}</th>
                  <th scope="col">{m.replacesColMonny()}</th>
                  <th scope="col" className="seo-col-action">
                    {m.replacesColDetails()}
                  </th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id}>
                    <th scope="row" className="seo-cell-category">
                      {row.category}
                    </th>
                    <td className="seo-cell-tools">{row.tools}</td>
                    <td className="seo-cell-monny">{row.monny}</td>
                    <td className="seo-col-action">
                      <Link to={row.to} hash={row.hash} className="seo-inline-link">
                        <span>{row.cta}</span>
                        <ArrowRight size={13} aria-hidden="true" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="seo-scope-bar">
          <p>{m.replacesScopeNote()}</p>
          <span className="seo-scope-badge mono">{m.replacesBadge()}</span>
        </div>
      </div>
    </section>
  )
}
