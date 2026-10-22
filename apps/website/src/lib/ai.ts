import type { Service } from '~/components/service-mark/ServiceMark'
import { formatDate, formatDollars, formatDuration } from '~/lib/format'
import { m } from '~/paraglide/messages.js'

export type AiTool = { service: Service; name: string; plan: string; ago: number; color: string; limits: { title: string; left: number; pace: number; reset: string }[] }

const weekdayTime: Intl.DateTimeFormatOptions = { weekday: 'short', hour: 'numeric', minute: '2-digit' }

/** Sample plans and readings drawn after the app's AI tab (Monny.sketch, popover frames 11–15). */
export function aiTools(): AiTool[] {
  return [
    {
      service: 'claude',
      name: 'Claude',
      plan: `Claude Code · ${m.ai_plan({ plan: 'Max' })}`,
      ago: 1,
      color: 'var(--monny-ai-claude)',
      limits: [
        { title: m.ai_five_hours(), left: 66, pace: 53, reset: m.ai_resets_in({ time: formatDuration(2, 38) }) },
        { title: m.ai_weekly(), left: 39, pace: 28, reset: m.ai_resets_on({ time: formatDate(new Date(2026, 9, 26, 9), weekdayTime) }) },
      ],
    },
    {
      service: 'codex',
      name: 'Codex',
      plan: `Codex · ${m.ai_plan({ plan: 'Pro' })}`,
      ago: 12,
      color: 'var(--monny-ai-codex)',
      limits: [
        { title: m.ai_five_hours(), left: 88, pace: 87, reset: m.ai_resets_in({ time: formatDuration(4, 21) }) },
        { title: m.ai_weekly(), left: 8, pace: 48, reset: m.ai_resets_on({ time: formatDate(new Date(2026, 9, 27, 18, 40), weekdayTime) }) },
      ],
    },
    {
      service: 'cursor',
      name: 'Cursor',
      plan: `Cursor · ${m.ai_plan({ plan: 'Pro' })}`,
      ago: 3,
      color: 'var(--monny-ai-cursor)',
      limits: [
        {
          title: m.ai_monthly_dollars({ left: formatDollars(12.4), total: formatDollars(20) }),
          left: 62,
          pace: 55,
          reset: m.ai_resets_on({ time: formatDate(new Date(2026, 10, 3), { month: 'short', day: 'numeric' }) }),
        },
      ],
    },
    {
      service: 'grok',
      name: 'Grok',
      plan: 'Grok CLI',
      ago: 5,
      color: 'var(--monny-ai-grok)',
      limits: [{ title: m.ai_weekly_credits(), left: 74, pace: 60, reset: m.ai_resets_on({ time: formatDate(new Date(2026, 9, 29, 12), weekdayTime) }) }],
    },
  ]
}
