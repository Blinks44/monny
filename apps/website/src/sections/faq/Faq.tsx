import {
  Accordion,
  AccordionItem,
  AccordionItemBody,
  AccordionItemContent,
  AccordionItemIndicator,
  AccordionItemTrigger,
} from '@moduix/react/accordion'
import { Card } from '@moduix/react/card'
import { Reveal, Section, SectionHeading } from '~/components'
import { faq } from '~/lib/faq'
import { m } from '~/paraglide/messages.js'
import styles from './Faq.module.css'

export function Faq() {
  return (
    <Section id="faq" narrow>
      <SectionHeading title={m.faq_title()} centered />
      <Reveal>
        <Card asChild className={styles.card}>
          <Accordion collapsible multiple defaultValue={['free']}>
            {faq().map(({ id, question, answer }) => (
              <AccordionItem key={id} value={id} className={styles.item}>
                <AccordionItemTrigger className={styles.question}>
                  {question}
                  <AccordionItemIndicator />
                </AccordionItemTrigger>
                <AccordionItemContent>
                  <AccordionItemBody>{answer}</AccordionItemBody>
                </AccordionItemContent>
              </AccordionItem>
            ))}
          </Accordion>
        </Card>
      </Reveal>
    </Section>
  )
}
