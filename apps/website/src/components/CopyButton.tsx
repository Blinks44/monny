import { Check, Copy } from 'lucide-react'
import { useState } from 'react'
import * as m from '@/integrations/i18n/paraglide/messages'

interface CopyButtonProps {
  text: string
  className?: string
  showLabelWhenIdle?: boolean
}

export function CopyButton({
  text,
  className = 'copy-icon-btn',
  showLabelWhenIdle = false,
}: CopyButtonProps) {
  const [copied, setCopied] = useState(false)

  const handleCopy = () => {
    void navigator.clipboard?.writeText(text).then(() => {
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1800)
    })
  }

  return (
    <button
      type="button"
      className={className}
      data-copied={copied}
      onClick={handleCopy}
      aria-label={copied ? m.heroCopied() : m.heroCopyCommand()}
      title={copied ? m.heroCopied() : m.heroCopyCommand()}
    >
      {copied ? <Check size={14} aria-hidden="true" /> : <Copy size={14} aria-hidden="true" />}
      {copied ? (
        <span>{m.heroCopied()}</span>
      ) : showLabelWhenIdle ? (
        <span>{m.heroCopyCommand()}</span>
      ) : null}
    </button>
  )
}
