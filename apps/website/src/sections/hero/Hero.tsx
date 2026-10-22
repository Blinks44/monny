import { Button } from '@moduix/react/button'
import { Heading } from '@moduix/react/heading'
import { Text } from '@moduix/react/text'
import { BatteryFull, Search, SlidersHorizontal, Wifi } from 'lucide-react'
import { motion } from 'motion/react'
import { Chip, DownloadButton, DownloadNote, Popover, Section } from '~/components'
import type { Release } from '~/lib/release'
import { m } from '~/paraglide/messages.js'
import styles from './Hero.module.css'

export function Hero({ release }: { release: Release | null }) {
  return (
    <Section flush className={styles.hero}>
      <Chip tone="success" large className={styles.badge}>
        {m.hero_badge()}
      </Chip>
      <Heading as="h1" className={styles.title}>
        {m.hero_title_start()} <em>{m.hero_title_accent()}</em>
      </Heading>
      <Text className={styles.lead}>{m.hero_lead()}</Text>
      <div className={styles.actions}>
        <DownloadButton release={release} />
        <Button asChild variant="outline" size="xl">
          <a href="#features">{m.hero_secondary()}</a>
        </Button>
      </div>
      <DownloadNote release={release} />
      <motion.div
        className={styles.desktop}
        initial={{ opacity: 0, y: 40, scale: 0.97 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.7, ease: [0.2, 0.8, 0.2, 1] }}
      >
        <div className={styles.menuBar} aria-hidden>
          <b className={styles.apps}>Finder</b>
          <span className={styles.item}>
            <MenuBarGlyph />
          </span>
          <span className={styles.status}>
            <Wifi size={15} strokeWidth={2.4} />
            <BatteryFull size={20} strokeWidth={1.8} />
            <Search size={15} strokeWidth={2.4} />
            <SlidersHorizontal size={15} strokeWidth={2.4} />
          </span>
        </div>
        <div className={styles.popover}>
          <Popover />
        </div>
      </motion.div>
    </Section>
  )
}

/** The monochrome menu bar template from `MonnyMenuBar.svg`. */
function MenuBarGlyph() {
  return (
    <svg width="16" height="14" viewBox="0 0 16 14" fill="currentColor">
      <rect x="0" y="5" width="4" height="8" rx="2" />
      <rect x="6" y="1" width="4" height="12" rx="2" />
      <rect x="12" y="7" width="4" height="6" rx="2" />
    </svg>
  )
}
