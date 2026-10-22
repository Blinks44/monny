/** Public repository and production origin; downloads appear after a stable DMG is published. */
export const site = {
  /** `owner/name` on GitHub. While null, the download button is a placeholder. */
  githubRepo: 'Blinks44/monny' as string | null,
  /** Absolute origin without a trailing slash; enables canonical, hreflang and Open Graph URLs. */
  url: 'https://monny.moduix.dev' as string | null,
}
