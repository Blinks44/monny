import { Clipboard, ClipboardControl, ClipboardIndicator, ClipboardInput, ClipboardTrigger } from '@moduix/react/clipboard'
import { m } from '~/paraglide/messages.js'
import styles from './InstallCommand.module.css'

/** Removes the download quarantine flag; the same command as the README's install section. */
const command = 'xattr -dr com.apple.quarantine /Applications/Monny.app'

export function InstallCommand() {
  return (
    <Clipboard value={command} className={styles.clipboard}>
      <ClipboardControl>
        <ClipboardInput className={styles.input} aria-label={m.install_command_label()} />
        <ClipboardTrigger className={styles.trigger}>
          <ClipboardIndicator />
          <ClipboardIndicator copied={m.install_copied()}>{m.install_copy()}</ClipboardIndicator>
        </ClipboardTrigger>
      </ClipboardControl>
    </Clipboard>
  )
}
