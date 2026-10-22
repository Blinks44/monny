import { Bell, Cpu, Globe, HardDrive, LayoutList, MemoryStick, PanelTop, Thermometer } from 'lucide-react'
import { FeatureCard, Section, SectionHeading } from '~/components'
import { m } from '~/paraglide/messages.js'
import styles from './Features.module.css'

export function Features() {
  const features = [
    { icon: Cpu, metric: 'cpu', title: m.feature_cpu_title(), text: m.feature_cpu_text() },
    { icon: MemoryStick, metric: 'memory', title: m.feature_memory_title(), text: m.feature_memory_text() },
    { icon: HardDrive, metric: 'disk', title: m.feature_disk_title(), text: m.feature_disk_text() },
    { icon: Globe, metric: 'network', title: m.feature_network_title(), text: m.feature_network_text() },
    { icon: Thermometer, metric: 'heat', title: m.feature_sensors_title(), text: m.feature_sensors_text() },
    { icon: LayoutList, metric: 'graphite', title: m.feature_processes_title(), text: m.feature_processes_text() },
    { icon: PanelTop, metric: 'accent', title: m.feature_menubar_title(), text: m.feature_menubar_text() },
    { icon: Bell, metric: 'upload', title: m.feature_alerts_title(), text: m.feature_alerts_text() },
  ] as const
  return (
    <Section id="features">
      <SectionHeading title={m.features_title()} lead={m.features_lead()} />
      <div className={styles.grid}>
        {features.map((feature, index) => (
          <FeatureCard key={feature.title} {...feature} delay={(index % 4) * 0.06} />
        ))}
      </div>
    </Section>
  )
}
