import { useCallback, useSyncExternalStore } from 'react'

export type ColorScheme = 'light' | 'dark'

const STORAGE_KEY = 'monny-theme'
const listeners = new Set<() => void>()

export const themeInitScript = `(() => {
  try {
    const param = new URLSearchParams(window.location.search).get('theme');
    const saved = localStorage.getItem('${STORAGE_KEY}');
    const preferred = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    const scheme =
      param === 'dark' || param === 'light'
        ? param
        : saved === 'dark' || saved === 'light'
          ? saved
          : preferred;
    document.documentElement.dataset.moduixColorScheme = scheme;
    document.documentElement.dataset.theme = scheme;
    document.documentElement.style.colorScheme = scheme;
  } catch {}
})();`

function readDomTheme(): ColorScheme {
  if (typeof document === 'undefined') return 'light'
  return document.documentElement.dataset.theme === 'dark' ? 'dark' : 'light'
}

function applyTheme(scheme: ColorScheme): void {
  if (typeof document === 'undefined') return
  document.documentElement.dataset.moduixColorScheme = scheme
  document.documentElement.dataset.theme = scheme
  document.documentElement.style.colorScheme = scheme
  for (const listener of listeners) listener()
}

function subscribe(listener: () => void): () => void {
  listeners.add(listener)
  if (typeof window === 'undefined') {
    return () => {
      listeners.delete(listener)
    }
  }
  const media = window.matchMedia('(prefers-color-scheme: dark)')
  const onSystemChange = (event: MediaQueryListEvent) => {
    try {
      if (!localStorage.getItem(STORAGE_KEY)) {
        applyTheme(event.matches ? 'dark' : 'light')
      }
    } catch {
      // Ignore storage errors in private browsing.
    }
  }
  media.addEventListener('change', onSystemChange)
  return () => {
    listeners.delete(listener)
    media.removeEventListener('change', onSystemChange)
  }
}

export function useTheme() {
  const theme = useSyncExternalStore<ColorScheme>(subscribe, readDomTheme, () => 'light')

  const toggleTheme = useCallback(() => {
    const next: ColorScheme = readDomTheme() === 'dark' ? 'light' : 'dark'
    applyTheme(next)
    try {
      localStorage.setItem(STORAGE_KEY, next)
    } catch {
      // Ignore storage errors in private browsing.
    }
  }, [])

  return { theme, toggleTheme }
}
