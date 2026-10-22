import { createServerFn } from '@tanstack/react-start'
import { site } from './site'

export type Release = { version: string; url: string }

const TTL = 10 * 60 * 1000
let cached: { at: number; release: Release | null } | undefined

/** Latest published DMG, or null while there is no public release. Runs on the server only. */
export const getLatestRelease = createServerFn({ method: 'GET' }).handler(async (): Promise<Release | null> => {
  if (!site.githubRepo) return null
  if (cached && Date.now() - cached.at < TTL) return cached.release
  cached = { at: Date.now(), release: await fetchLatestRelease(site.githubRepo).catch(() => null) }
  return cached.release
})

async function fetchLatestRelease(repo: string): Promise<Release | null> {
  const response = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
    headers: { Accept: 'application/vnd.github+json', 'User-Agent': 'Monny-Website' },
  })
  if (!response.ok) return null
  const data = (await response.json()) as { tag_name: string; assets: { name: string; browser_download_url: string }[] }
  const dmg = data.assets.find((asset) => asset.name.endsWith('.dmg'))
  return dmg ? { version: data.tag_name.replace(/^v/, ''), url: dmg.browser_download_url } : null
}
