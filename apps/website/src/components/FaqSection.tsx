import {
  Accordion,
  AccordionItem,
  AccordionItemBody,
  AccordionItemContent,
  AccordionItemIndicator,
  AccordionItemTrigger,
} from '@moduix/react/accordion'
import { Link } from '@tanstack/react-router'
import { ArrowRight, ChevronDown } from 'lucide-react'
import type { Locale } from '@/config/locales'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { FaqEntry } from '@/integrations/seo'

export function getLandingFaqItems(locale: Locale): FaqEntry[] {
  return [
    { question: m.faq6Q({}, { locale }), answer: m.faq6A({}, { locale }) },
    { question: m.faq2Q({}, { locale }), answer: m.faq2A({}, { locale }) },
    { question: m.faq3Q({}, { locale }), answer: m.faq3A({}, { locale }) },
    { question: m.faq7Q({}, { locale }), answer: m.faq7A({}, { locale }) },
    { question: m.faq1Q({}, { locale }), answer: m.faq1A({}, { locale }) },
    { question: m.faq4Q({}, { locale }), answer: m.faq4A({}, { locale }) },
    { question: m.faq5Q({}, { locale }), answer: m.faq5A({}, { locale }) },
  ]
}

export function FaqSection() {
  const items = [
    { id: 'replace', q: m.faq6Q(), a: m.faq6A() },
    { id: 'battery', q: m.faq2Q(), a: m.faq2A() },
    { id: 'ai-privacy', q: m.faq3Q(), a: m.faq3A() },
    { id: 'overhead', q: m.faq7Q(), a: m.faq7A() },
    { id: 'gatekeeper', q: m.faq1Q(), a: m.faq1A() },
    { id: 'desktop-mac', q: m.faq4Q(), a: m.faq4A() },
    { id: 'updates', q: m.faq5Q(), a: m.faq5A() },
  ]

  const links = [
    { to: '/alternatives/istat-menus/' as const, label: m.faqLinkIstat() },
    { to: '/alternatives/aldente/' as const, label: m.faqLinkAldente() },
    { to: '/guides/ai-coding-quotas/' as const, label: m.faqLinkAi() },
    { to: '/guides/port-pid-finder/' as const, label: m.faqLinkPorts() },
  ]

  return (
    <section id="faq" className="faq-section" data-reveal>
      <div className="container">
        <div className="section-header">
          <span className="eyebrow-label">{m.faqEyebrow()}</span>
          <h2 className="section-title">{m.faqTitle()}</h2>
          <p className="section-subtitle">{m.faqSubtitle()}</p>
        </div>

        <Accordion collapsible defaultValue={['replace']} className="faq-list">
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

        <div className="seo-faq-links-box">
          <span className="seo-faq-links-label">{m.faqLinksLabel()}</span>
          <div className="seo-faq-links-grid">
            {links.map((link) => (
              <Link key={link.to} to={link.to} className="seo-faq-pill">
                <span>{link.label}</span>
                <ArrowRight size={13} aria-hidden="true" />
              </Link>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
