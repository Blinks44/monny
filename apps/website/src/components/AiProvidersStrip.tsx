import { AiLogo, type AiLogoId } from '@/components/AiLogo'
import * as m from '@/integrations/i18n/paraglide/messages'
import type { ColorScheme } from '@/lib/theme'

interface AiProvidersStripProps {
  theme: ColorScheme
}

const PROVIDERS: Array<{ id: AiLogoId; name: string }> = [
  { id: 'claude', name: 'Claude Code' },
  { id: 'codex', name: 'Codex CLI' },
  { id: 'cursor', name: 'Cursor' },
  { id: 'copilot', name: 'GitHub Copilot' },
  { id: 'gemini', name: 'Gemini CLI' },
  { id: 'antigravity', name: 'Antigravity' },
  { id: 'windsurf', name: 'Windsurf' },
  { id: 'jetbrains', name: 'JetBrains AI' },
  { id: 'cline', name: 'Cline' },
  { id: 'grok', name: 'Grok' },
  { id: 'kimi', name: 'Kimi' },
  { id: 'augment', name: 'Augment' },
]

export function AiProvidersStrip({ theme }: AiProvidersStripProps) {
  return (
    <section id="ai-quotas" className="ecosystem-strip" aria-label={m.ecosystemLabel()}>
      <div className="container">
        <p className="ecosystem-label">{m.ecosystemLabel()}</p>
        <div className="ecosystem-pills">
          {PROVIDERS.map((tool) => (
            <span key={tool.id} className="ecosystem-pill">
              <AiLogo id={tool.id} alt={tool.name} theme={theme} size={17} />
              <span>{tool.name}</span>
            </span>
          ))}
          <span className="ecosystem-pill ecosystem-pill-more">{m.ecosystemMore()}</span>
        </div>
      </div>
    </section>
  )
}
