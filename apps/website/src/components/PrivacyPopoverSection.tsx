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
import { BatteryCharging, KeyRound, Lock, ShieldCheck } from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'

export function PrivacyPopoverSection() {
  const [zoomed, setZoomed] = useState<{ src: string; caption: string } | null>(null)
  const [lightboxOpen, setLightboxOpen] = useState(false)

  const rules = [
    {
      icon: <ShieldCheck size={16} className="privacy-rule-ico" aria-hidden="true" />,
      title: m.privacyRule1Title(),
      desc: m.privacyRule1Desc(),
    },
    {
      icon: <BatteryCharging size={16} className="privacy-rule-ico" aria-hidden="true" />,
      title: m.privacyRule2Title(),
      desc: m.privacyRule2Desc(),
    },
    {
      icon: <Lock size={16} className="privacy-rule-ico" aria-hidden="true" />,
      title: m.privacyRule3Title(),
      desc: m.privacyRule3Desc(),
    },
    {
      icon: <KeyRound size={16} className="privacy-rule-ico" aria-hidden="true" />,
      title: m.privacyRule4Title(),
      desc: m.privacyRule4Desc(),
    },
  ]

  const popovers = [
    {
      src: '/screenshots/popovers/popover-overview-dark.webp',
      caption: m.privacyPopover1Caption(),
    },
    {
      src: '/screenshots/popovers/popover-ports-dark.webp',
      caption: m.privacyPopover2Caption(),
    },
  ]

  return (
    <section id="privacy" className="privacy-section" data-reveal>
      <div className="container">
        <div className="privacy-band">
          <div>
            <span className="eyebrow-label">{m.privacyEyebrow()}</span>
            <h2>{m.privacyTitle()}</h2>
            <p className="privacy-lead">{m.privacySubtitle()}</p>

            <ul className="privacy-rules">
              {rules.map((rule, idx) => (
                <li key={idx} className="privacy-rule">
                  <div className="privacy-rule-head">
                    {rule.icon}
                    <span>{rule.title}</span>
                  </div>
                  <p>{rule.desc}</p>
                </li>
              ))}
            </ul>
          </div>

          <div className="privacy-popovers">
            {popovers.map((item) => (
              <div key={item.src} className="privacy-popover-card">
                <button
                  type="button"
                  className="privacy-popover-frame"
                  onClick={() => {
                    setZoomed(item)
                    setLightboxOpen(true)
                  }}
                  aria-label={item.caption}
                >
                  <img src={item.src} alt={item.caption} width={712} height={1264} loading="lazy" />
                </button>
                <span className="privacy-popover-caption">{item.caption}</span>
              </div>
            ))}
          </div>
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
          <DialogContent className="lightbox-content lightbox-content-popover">
            <DialogHeader className="lightbox-header">
              <DialogTitle>{zoomed?.caption ?? ''}</DialogTitle>
              <DialogCloseIcon />
            </DialogHeader>
            <DialogBody className="lightbox-body lightbox-body-popover">
              {zoomed ? (
                <img src={zoomed.src} alt={zoomed.caption} width={712} height={1264} />
              ) : null}
            </DialogBody>
          </DialogContent>
        </DialogPositioner>
      </Dialog>
    </section>
  )
}
