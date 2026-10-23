import { Tabs, TabsList, TabsIndicator, TabsTrigger, TabsContent } from '@moduix/react/tabs'
import { ProductImage } from '@/components/product-image'
import { m } from '@/integrations/i18n/paraglide/messages'
import { BatteryDemo } from '../battery-demo'
import styles from './DashboardSection.module.css'

export function DashboardSection() {
  const views = [
    ['overview', m.overview()],
    ['cpu', m.cpu()],
    ['memory', m.memory()],
    ['disk', m.disk()],
    ['network', m.network()],
    ['battery', m.battery()],
    ['sensors', m.sensors()],
  ] as const
  return (
    <Tabs defaultValue="cpu" className={styles.tabs} lazyMount>
      <div className={styles.scroll}>
        <TabsList aria-label={m.dashboard()} className={styles.list}>
          {views.map(([view, label]) => (
            <TabsTrigger key={view} value={view}>
              {label}
            </TabsTrigger>
          ))}
          <TabsIndicator />
        </TabsList>
      </div>
      {views.map(([view, label]) => (
        <TabsContent key={view} value={view} className={styles.panel}>
          {view === 'battery' ? (
            <div className={styles.battery}>
              <BatteryDemo />
            </div>
          ) : (
            <ProductImage view={view} alt={m.screenshotAlt({ view: label })} />
          )}
        </TabsContent>
      ))}
      <div className={styles.facts}>
        <span>{m.historyFact()}</span>
        <span>{m.appearanceFact()}</span>
        <span lang="en">English, Русский, Deutsch, Français, Español, 简体中文</span>
      </div>
    </Tabs>
  )
}
