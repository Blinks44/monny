import { m } from '~/paraglide/messages.js'

/** Questions shown on the page and published as FAQPage structured data. */
export const faq = () => [
  { id: 'free', question: m.faq_free_q(), answer: m.faq_free_a() },
  { id: 'mac', question: m.faq_mac_q(), answer: m.faq_mac_a() },
  { id: 'limit', question: m.faq_limit_q(), answer: m.faq_limit_a() },
  { id: 'cost', question: m.faq_cost_q(), answer: m.faq_cost_a() },
  { id: 'privacy', question: m.faq_privacy_q(), answer: m.faq_privacy_a() },
  { id: 'warning', question: m.faq_warning_q(), answer: m.faq_warning_a() },
  { id: 'sensors', question: m.faq_sensors_q(), answer: m.faq_sensors_a() },
]
