import { Button } from '@moduix/react/button'
import { clsx } from 'clsx'
import { Download } from 'lucide-react'
import type { Release } from '~/lib/release'
import { m } from '~/paraglide/messages.js'
import styles from './DownloadButton.module.css'

/** A real link once a release exists; until then a disabled button that says so. */
export function DownloadButton({ release, inverted }: { release: Release | null; inverted?: boolean }) {
  const className = clsx(styles.button, inverted && styles.inverted)
  if (!release) {
    return (
      <Button size="xl" className={className} disabled>
        <Download size={18} aria-hidden /> {m.download()}
        <span className={styles.soon}>{m.download_soon()}</span>
      </Button>
    )
  }
  return (
    <Button asChild size="xl" className={className}>
      <a href={release.url}>
        <Download size={18} aria-hidden /> {m.download()}
      </a>
    </Button>
  )
}

export function DownloadNote({ release, inverted }: { release: Release | null; inverted?: boolean }) {
  return (
    <p className={clsx(styles.note, inverted && styles.invertedNote)}>
      {release ? m.download_version({ version: release.version }) : m.download_pending()} · {m.requirement()}
    </p>
  )
}
