import { useEffect } from 'react'

export function useRevealObserver(): void {
  useEffect(() => {
    if (typeof window === 'undefined') return
    const nodes = Array.from(document.querySelectorAll<HTMLElement>('[data-reveal]'))
    if (nodes.length === 0) return

    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (reduced || typeof IntersectionObserver === 'undefined') {
      for (const el of nodes) {
        el.dataset.revealed = 'true'
      }
      return
    }

    document.documentElement.dataset.revealReady = 'true'

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            const target = entry.target as HTMLElement
            target.dataset.revealed = 'true'
            observer.unobserve(target)
          }
        }
      },
      { rootMargin: '0px 0px -10px 0px', threshold: 0.01 },
    )

    for (const el of nodes) {
      observer.observe(el)
    }

    return () => observer.disconnect()
  }, [])
}
