import { Alert } from '@moduix/react/alert'
import { Tabs, TabsList, TabsIndicator, TabsTrigger, TabsContent } from '@moduix/react/tabs'
import { TriangleAlert } from 'lucide-react'
import { CopyButton } from '@/components/copy-button'
import { site } from '@/config/site'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './InstallNotice.module.css'

const command = 'xattr -dr com.apple.quarantine /Applications/Monny.app'

export function InstallNotice({ compact = false }: { compact?: boolean }) {
  if (compact)
    return (
      <Alert status="warning" role="note" className={styles.inline}>
        <TriangleAlert size={16} aria-hidden="true" />
        <span>{m.noticeInline()}</span>
        <a href="#install">{m.howToOpen()}</a>
      </Alert>
    )
  return (
    <Alert status="warning" role="note" className={styles.full}>
      <div className={styles.explanation}>
        <span className={styles.icon}>
          <TriangleAlert size={20} aria-hidden="true" />
        </span>
        <h3>{m.noticeTitle()}</h3>
        <p>{m.noticeDescription()}</p>
        <blockquote>{m.noticeQuote()}</blockquote>
        <div className={styles.links}>
          <a href="https://support.apple.com/en-us/102445">{m.appleGuide()}</a>
          <a href={`${site.repository}#build-and-run`}>{m.buildSource()}</a>
        </div>
      </div>
      <Tabs defaultValue="terminal" variant="line" className={styles.tabs}>
        <TabsList aria-label={m.firstLaunchOptions()}>
          <TabsTrigger value="terminal">{m.terminal()}</TabsTrigger>
          <TabsTrigger value="settings">{m.systemSettings()}</TabsTrigger>
          <TabsIndicator />
        </TabsList>
        <TabsContent value="terminal" className={styles.panel}>
          <div className={styles.command}>
            <code>
              <span aria-hidden="true">$ </span>
              {command}
            </code>
            <CopyButton value={command} label={m.copy()} iconOnly />
          </div>
          <ol>
            <li>{m.openTerminal()}</li>
            <li>{m.pasteCommand()}</li>
            <li>{m.openNormally()}</li>
          </ol>
        </TabsContent>
        <TabsContent value="settings" className={styles.panel}>
          <ol>
            <li>{m.settingsStep1()}</li>
            <li>{m.settingsStep2()}</li>
            <li>{m.settingsStep3()}</li>
          </ol>
        </TabsContent>
        <p className={styles.footnote}>{m.noticeFootnote()}</p>
      </Tabs>
    </Alert>
  )
}
