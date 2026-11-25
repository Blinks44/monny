import { Link } from '@tanstack/react-router'
import { ArrowRight, BatteryCharging, Check, Cpu, Sparkles } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'

export function WhoItIsForSection() {
  const cards = [
    {
      id: 'dev',
      tone: 'accent' as const,
      icon: Sparkles,
      label: m.whoDevLabel(),
      title: m.whoDevTitle(),
      description: m.whoDevDesc(),
      bullets: [m.whoDevBullet1(), m.whoDevBullet2(), m.whoDevBullet3()],
      ctaLabel: m.whoDevCta(),
      to: '/guides/ai-coding-quotas/' as const,
    },
    {
      id: 'battery',
      tone: 'teal' as const,
      icon: BatteryCharging,
      label: m.whoBatteryLabel(),
      title: m.whoBatteryTitle(),
      description: m.whoBatteryDesc(),
      bullets: [m.whoBatteryBullet1(), m.whoBatteryBullet2(), m.whoBatteryBullet3()],
      ctaLabel: m.whoBatteryCta(),
      to: '/alternatives/aldente/' as const,
    },
    {
      id: 'power',
      tone: 'neutral' as const,
      icon: Cpu,
      label: m.whoPowerLabel(),
      title: m.whoPowerTitle(),
      description: m.whoPowerDesc(),
      bullets: [m.whoPowerBullet1(), m.whoPowerBullet2(), m.whoPowerBullet3()],
      ctaLabel: m.whoPowerCta(),
      to: '/alternatives/istat-menus/' as const,
    },
  ]

  return (
    <section id="who" className="seo-section" data-reveal>
      <div className="container">
        <div className="section-header">
          <span className="eyebrow-label">{m.whoEyebrow()}</span>
          <h2 className="section-title">{m.whoTitle()}</h2>
          <p className="section-subtitle">{m.whoSubtitle()}</p>
        </div>

        <div className="seo-who-grid seo-who-grid-3">
          {cards.map((card) => {
            const Icon = card.icon
            return (
              <article key={card.id} className={`seo-who-card seo-who-card-${card.tone}`}>
                <div className="seo-who-label-row">
                  <span className={`seo-who-badge seo-who-badge-${card.tone}`}>
                    <Icon size={13} aria-hidden="true" />
                    <span>{card.label}</span>
                  </span>
                </div>
                <h3>{card.title}</h3>
                <p className="seo-who-desc">{card.description}</p>
                <ul className="seo-check-list">
                  {card.bullets.map((bullet) => (
                    <li key={bullet}>
                      <Check size={15} className="seo-check-icon" aria-hidden="true" />
                      <span>{bullet}</span>
                    </li>
                  ))}
                </ul>
                <Link to={card.to} className="seo-card-link">
                  <span>{card.ctaLabel}</span>
                  <ArrowRight size={14} aria-hidden="true" />
                </Link>
              </article>
            )
          })}
        </div>
      </div>
    </section>
  )
}
