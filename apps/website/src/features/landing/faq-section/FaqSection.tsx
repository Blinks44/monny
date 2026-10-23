import {
  Accordion,
  AccordionItem,
  AccordionItemTrigger,
  AccordionItemIndicator,
  AccordionItemContent,
  AccordionItemBody,
} from '@moduix/react/accordion'
import { Minus, Plus } from 'lucide-react'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './FaqSection.module.css'

export function FaqSection() {
  const questions = [
    [m.faqQ1(), m.faqA1()],
    [m.faqQ2(), m.faqA2()],
    [m.faqQ3(), m.faqA3()],
    [m.faqQ4(), m.faqA4()],
    [m.faqQ5(), m.faqA5()],
    [m.faqQ6(), m.faqA6()],
  ]
  return (
    <section id="faq" className={styles.section} aria-labelledby="faq-title">
      <div className={styles.intro}>
        <h2 id="faq-title">{m.questions()}</h2>
        <p>{m.questionsLead()}</p>
        <a href={`${site.repository}/issues`}>{m.askGithub()}</a>
      </div>
      <Accordion collapsible defaultValue={['0']} className={styles.accordion}>
        {questions.map(([question, answer], index) => (
          <AccordionItem key={question} value={String(index)}>
            <h3>
              <AccordionItemTrigger>
                {question}
                <AccordionItemIndicator>
                  <Plus className={styles.plus} size={18} aria-hidden="true" />
                  <Minus className={styles.minus} size={18} aria-hidden="true" />
                </AccordionItemIndicator>
              </AccordionItemTrigger>
            </h3>
            <AccordionItemContent>
              <AccordionItemBody>{answer}</AccordionItemBody>
            </AccordionItemContent>
          </AccordionItem>
        ))}
      </Accordion>
    </section>
  )
}
