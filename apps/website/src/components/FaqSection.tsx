import {
  Accordion,
  AccordionItem,
  AccordionItemBody,
  AccordionItemContent,
  AccordionItemIndicator,
  AccordionItemTrigger,
} from '@moduix/react/accordion'
import { ChevronDown } from 'lucide-react'
import * as m from '@/integrations/i18n/paraglide/messages'

export function FaqSection() {
  const items = [
    { id: 'gatekeeper', q: m.faq1Q(), a: m.faq1A() },
    { id: 'battery', q: m.faq2Q(), a: m.faq2A() },
    { id: 'ai-privacy', q: m.faq3Q(), a: m.faq3A() },
    { id: 'desktop-mac', q: m.faq4Q(), a: m.faq4A() },
    { id: 'updates', q: m.faq5Q(), a: m.faq5A() },
  ]

  return (
    <section id="faq" className="faq-section" data-reveal>
      <div className="container">
        <div className="section-header">
          <span className="eyebrow-label">{m.faqEyebrow()}</span>
          <h2 className="section-title">{m.faqTitle()}</h2>
          <p className="section-subtitle">{m.faqSubtitle()}</p>
        </div>

        <Accordion collapsible defaultValue={['gatekeeper']} className="faq-list">
          {items.map((item) => (
            <AccordionItem key={item.id} value={item.id} className="faq-item">
              <AccordionItemTrigger className="faq-trigger">
                <span>{item.q}</span>
                <AccordionItemIndicator>
                  <ChevronDown size={16} aria-hidden="true" />
                </AccordionItemIndicator>
              </AccordionItemTrigger>
              <AccordionItemContent>
                <AccordionItemBody className="faq-body">{item.a}</AccordionItemBody>
              </AccordionItemContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  )
}
