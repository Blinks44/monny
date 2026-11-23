import type { ColorScheme } from '@/lib/theme'

export type AiLogoId =
  | 'claude'
  | 'codex'
  | 'cursor'
  | 'antigravity'
  | 'copilot'
  | 'jetbrains'
  | 'grok'
  | 'gemini'
  | 'windsurf'
  | 'cline'
  | 'kimi'
  | 'augment'

const DUAL_THEME = new Set<AiLogoId>(['codex', 'cursor', 'copilot'])
const INVERT_IN_DARK = new Set<AiLogoId>(['grok', 'windsurf', 'cline', 'augment'])
const INVERT_IN_LIGHT = new Set<AiLogoId>(['jetbrains'])

interface AiLogoProps {
  id: AiLogoId
  alt: string
  theme: ColorScheme
  size?: number
}

export function AiLogo({ id, alt, theme, size = 18 }: AiLogoProps) {
  const src = theme === 'dark' && DUAL_THEME.has(id) ? `/logos/${id}-dark.svg` : `/logos/${id}.svg`
  const invert = INVERT_IN_DARK.has(id) ? 'dark' : INVERT_IN_LIGHT.has(id) ? 'light' : undefined

  return (
    <img
      src={src}
      alt={alt}
      width={size}
      height={size}
      className="ai-logo"
      data-invert={invert}
      loading="lazy"
    />
  )
}
