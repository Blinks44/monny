import { Button } from '@moduix/react/button'
import { ArrowUpRight, Download } from 'lucide-react'
import { CopyButton } from '@/components/copy-button'
import { site } from '@/config/site'
import { localePath } from '@/config/locales'
import { m } from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import styles from './DownloadActions.module.css'

export function DownloadActions({ mobileCopy = false }: { mobileCopy?: boolean }) {
  return (
    <div className={styles.actions}>
      <Button asChild size="xl">
        <a href={site.downloadUrl ?? site.releases}>
          <Download size={18} aria-hidden="true" />
          {m.download()}
        </a>
      </Button>
      <Button
        asChild
        variant="outline"
        size="xl"
        className={mobileCopy ? styles.github : undefined}
      >
        <a href={site.repository}>
          {m.github()}
          <ArrowUpRight size={16} aria-hidden="true" />
        </a>
      </Button>
      {mobileCopy && (
        <div className={styles.copy}>
          <CopyButton value={`${site.origin}${localePath(getLocale())}`} label={m.copyLink()} />
        </div>
      )}
    </div>
  )
}
