import { Button } from '@moduix/react/button'
import { Clipboard, ClipboardContext, ClipboardTrigger } from '@moduix/react/clipboard'
import { Tooltip, TooltipTrigger, TooltipPositioner, TooltipContent } from '@moduix/react/tooltip'
import { Check, Copy } from 'lucide-react'
import { m } from '@/integrations/i18n/paraglide/messages'
import styles from './CopyButton.module.css'

export function CopyButton({
  value,
  label,
  iconOnly = false,
}: {
  value: string
  label: string
  iconOnly?: boolean
}) {
  return (
    <Clipboard value={value} className={styles.root}>
      <ClipboardContext>
        {(clipboard) => (
          <>
            <Tooltip open={clipboard.copied ? true : undefined} disabled={!iconOnly}>
              <TooltipTrigger asChild>
                <ClipboardTrigger asChild aria-label={clipboard.copied ? m.copied() : label}>
                  <Button
                    variant="outline"
                    size={iconOnly ? 'icon-md' : 'xl'}
                    aria-label={iconOnly ? label : undefined}
                  >
                    {clipboard.copied ? (
                      <Check size={18} aria-hidden="true" />
                    ) : (
                      <Copy size={18} aria-hidden="true" />
                    )}
                    {!iconOnly && (clipboard.copied ? m.copied() : label)}
                  </Button>
                </ClipboardTrigger>
              </TooltipTrigger>
              <TooltipPositioner>
                <TooltipContent>{clipboard.copied ? m.copied() : label}</TooltipContent>
              </TooltipPositioner>
            </Tooltip>
            <output className={styles.status}>{clipboard.copied ? m.copied() : ''}</output>
          </>
        )}
      </ClipboardContext>
    </Clipboard>
  )
}
