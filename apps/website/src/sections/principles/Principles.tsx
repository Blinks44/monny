import { BadgeCheck, CircleSlash, Feather, LockKeyhole, RefreshCw, Sparkles } from 'lucide-react'
import { FeatureCard, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Principles.module.css'

export function Principles() {
  return (
    <Section id="private">
      <SectionHeading title={m.principles_title()} />
      <div className={styles.grid}>
        <FeatureCard className={styles.large} icon={LockKeyhole} metric="graphite" title={m.principle_private_title()} text={m.principle_private_text()} />
        <FeatureCard className={styles.large} icon={Feather} metric="memory" title={m.principle_light_title()} text={m.principle_light_text()} delay={0.06} />
        <FeatureCard icon={CircleSlash} metric="heat" title={m.principle_honest_title()} text={m.principle_honest_text()} />
        <FeatureCard icon={Sparkles} metric="cpu" title={m.principle_native_title()} text={m.principle_native_text()} delay={0.06} />
        <FeatureCard icon={BadgeCheck} metric="battery" title={m.principle_free_title()} text={m.principle_free_text()} delay={0.12} />
        <FeatureCard icon={RefreshCw} metric="network" title={m.principle_updates_title()} text={m.principle_updates_text()} delay={0.18} />
      </div>
    </Section>
  )
}
