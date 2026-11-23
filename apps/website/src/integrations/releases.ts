import { createServerFn } from '@tanstack/react-start'
import { site } from '@/config/site'

export interface ReleaseAssets {
  version: string
  tag: string
  releaseUrl: string
  dmgUrl: string
  checksumsUrl: string
  appcastUrl: string
  isFallback: boolean
}

interface GitHubReleaseAsset {
  name?: string
  browser_download_url?: string
}

interface GitHubReleasePayload {
  tag_name?: string
  html_url?: string
  assets?: GitHubReleaseAsset[]
}

const CACHE_TTL_MS = 15 * 60 * 1000
const FETCH_TIMEOUT_MS = 3500

let cached: { value: ReleaseAssets; expiresAt: number } | null = null

export function fallbackReleaseAssets(): ReleaseAssets {
  return {
    version: site.defaultVersion,
    tag: `v${site.defaultVersion}`,
    releaseUrl: site.latestRelease,
    dmgUrl: site.latestDmg,
    checksumsUrl: `${site.latestRelease}/download/SHA256SUMS.txt`,
    appcastUrl: `${site.latestRelease}/download/appcast.xml`,
    isFallback: true,
  }
}

export function parseGitHubRelease(payload: GitHubReleasePayload): ReleaseAssets {
  const rawTag = payload.tag_name?.trim() || `v${site.defaultVersion}`
  const version = rawTag.replace(/^v/i, '') || site.defaultVersion
  const releaseUrl = payload.html_url?.trim() || site.latestRelease
  const assets = Array.isArray(payload.assets) ? payload.assets : []

  const findAsset = (predicate: (name: string) => boolean, fallback: string): string => {
    const match = assets.find(
      (item) => item.name && item.browser_download_url && predicate(item.name.toLowerCase()),
    )
    return match?.browser_download_url ?? fallback
  }

  return {
    version,
    tag: rawTag,
    releaseUrl,
    dmgUrl: findAsset((name) => name.endsWith('.dmg'), site.latestDmg),
    checksumsUrl: findAsset(
      (name) => name === 'sha256sums.txt' || name === 'sha256sums',
      releaseUrl,
    ),
    appcastUrl: findAsset((name) => name === 'appcast.xml', releaseUrl),
    isFallback: false,
  }
}

export async function fetchLatestRelease(
  fetcher: typeof fetch = fetch,
  now = Date.now(),
): Promise<ReleaseAssets> {
  if (cached && now < cached.expiresAt) {
    return cached.value
  }

  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS)

  try {
    const response = await fetcher(
      `https://api.github.com/repos/${site.repoOwner}/${site.repoName}/releases/latest`,
      {
        headers: {
          Accept: 'application/vnd.github+json',
          'User-Agent': 'monny-website',
        },
        signal: controller.signal,
      },
    )
    if (!response.ok) {
      const fallback = fallbackReleaseAssets()
      cached = { value: fallback, expiresAt: now + 5 * 60 * 1000 }
      return fallback
    }
    const payload = (await response.json()) as GitHubReleasePayload
    const parsed = parseGitHubRelease(payload)
    cached = { value: parsed, expiresAt: now + CACHE_TTL_MS }
    return parsed
  } catch {
    const fallback = fallbackReleaseAssets()
    cached = { value: fallback, expiresAt: now + 2 * 60 * 1000 }
    return fallback
  } finally {
    clearTimeout(timer)
  }
}

export function resetReleaseCache(): void {
  cached = null
}

export const getLatestRelease = createServerFn({ method: 'GET' }).handler(async () => {
  return fetchLatestRelease()
})
