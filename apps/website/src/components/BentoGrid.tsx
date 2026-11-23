import {
  Dialog,
  DialogBackdrop,
  DialogBody,
  DialogCloseIcon,
  DialogContent,
  DialogHeader,
  DialogPositioner,
  DialogTitle,
} from '@moduix/react/dialog'
import { Maximize2 } from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

interface BentoGridProps {
  theme: ColorScheme
}

type BentoScreenId = 'cpu' | 'ai-usage' | 'memory' | 'sensors' | 'network' | 'disk'

export function BentoGrid({ theme }: BentoGridProps) {
  const [zoomed, setZoomed] = useState<{ id: BentoScreenId; title: string } | null>(null)
  const [lightboxOpen, setLightboxOpen] = useState(false)

  const cards: Array<{
    id: BentoScreenId
    pill: string
    pillClass: string
    title: string
    desc: string
  }> = [
    {
      id: 'cpu',
      pill: m.bentoCard1Pill(),
      pillClass: 'pill-accent',
      title: m.bentoCard1Title(),
      desc: m.bentoCard1Desc(),
    },
    {
      id: 'ai-usage',
      pill: m.bentoCard2Pill(),
      pillClass: 'pill-accent',
      title: m.bentoCard2Title(),
      desc: m.bentoCard2Desc(),
    },
    {
      id: 'memory',
      pill: m.bentoCard3Pill(),
      pillClass: 'pill-teal',
      title: m.bentoCard3Title(),
      desc: m.bentoCard3Desc(),
    },
    {
      id: 'sensors',
      pill: m.bentoCard4Pill(),
      pillClass: 'pill-amber',
      title: m.bentoCard4Title(),
      desc: m.bentoCard4Desc(),
    },
    {
      id: 'network',
      pill: m.bentoCard5Pill(),
      pillClass: 'pill-teal',
      title: m.bentoCard5Title(),
      desc: m.bentoCard5Desc(),
    },
    {
      id: 'disk',
      pill: m.bentoCard6Pill(),
      pillClass: 'pill-green',
      title: m.bentoCard6Title(),
      desc: m.bentoCard6Desc(),
    },
  ]

  return (
    <section id="bento" className="bento-section" data-reveal>
      <div className="container">
        <div className="section-header">
          <span className="eyebrow-label">{m.bentoEyebrow()}</span>
          <h2 className="section-title">{m.bentoTitle()}</h2>
          <p className="section-subtitle">{m.bentoSubtitle()}</p>
        </div>

        <div className="bento-grid">
          {cards.map((card) => (
            <article key={card.id} className="bento-card">
              <div>
                <span className={`pill ${card.pillClass}`}>{card.pill}</span>
              </div>
              <h3>{card.title}</h3>
              <p>{card.desc}</p>
              <button
                type="button"
                className="bento-shot-btn"
                onClick={() => {
                  setZoomed({ id: card.id, title: card.title })
                  setLightboxOpen(true)
                }}
                aria-label={`${m.bentoClickZoom()}: ${card.title}`}
              >
                <img
                  src={`/screenshots/panels/${card.id}-${theme}.webp`}
                  alt={card.title}
                  width={1616}
                  height={1400}
                  loading="lazy"
                />
                <span className="bento-zoom-chip" aria-hidden="true">
                  <Maximize2 size={11} />
                  <span>{m.bentoClickZoom()}</span>
                </span>
              </button>
            </article>
          ))}
        </div>
      </div>

      <Dialog
        open={lightboxOpen}
        onOpenChange={(details) => {
          setLightboxOpen(details.open)
        }}
      >
        <DialogBackdrop />
        <DialogPositioner>
          <DialogContent className="lightbox-content">
            <DialogHeader className="lightbox-header">
              <DialogTitle>
                {m.workflowsRealScreen()} · {zoomed?.title ?? ''}
              </DialogTitle>
              <DialogCloseIcon />
            </DialogHeader>
            <DialogBody className="lightbox-body">
              {zoomed ? (
                <img src={`/screenshots/${zoomed.id}-${theme}.webp`} alt={zoomed.title} />
              ) : null}
            </DialogBody>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </section>
  )
}
