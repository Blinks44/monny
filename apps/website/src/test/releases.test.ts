import { beforeEach, describe, expect, it, vi } from 'vitest'
import { site } from '@/config/site'
import {
  fallbackReleaseAssets,
  fetchLatestRelease,
  parseGitHubRelease,
  resetReleaseCache,
} from '@/integrations/releases'

describe('releases integration', () => {
  beforeEach(() => {
    resetReleaseCache()
  })

  it('parses Monny release assets from GitHub API payload', () => {
    const parsed = parseGitHubRelease({
      tag_name: 'v1.8.3',
      html_url: 'https://github.com/Blinks44/monny/releases/tag/v1.8.3',
      assets: [
        {
          name: 'Monny.dmg',
          browser_download_url:
            'https://github.com/Blinks44/monny/releases/download/v1.8.3/Monny.dmg',
        },
        {
          name: 'SHA256SUMS.txt',
          browser_download_url:
            'https://github.com/Blinks44/monny/releases/download/v1.8.3/SHA256SUMS.txt',
        },
        {
          name: 'appcast.xml',
          browser_download_url:
            'https://github.com/Blinks44/monny/releases/download/v1.8.3/appcast.xml',
        },
      ],
    })

    expect(parsed.version).toBe('1.8.3')
    expect(parsed.tag).toBe('v1.8.3')
    expect(parsed.dmgUrl).toContain('/v1.8.3/Monny.dmg')
    expect(parsed.checksumsUrl).toContain('/v1.8.3/SHA256SUMS.txt')
    expect(parsed.isFallback).toBe(false)
  })

  it('resolves latest release from /releases/latest redirect without hitting GitHub API', async () => {
    let calls = 0
    const mockFetch = async (input: string | URL | Request) => {
      calls++
      expect(String(input)).toBe(site.latestRelease)
      return new Response(null, {
        status: 302,
        headers: { Location: 'https://github.com/Blinks44/monny/releases/tag/v1.8.3' },
      })
    }

    const first = await fetchLatestRelease(mockFetch as typeof fetch, 1_000_000)
    const second = await fetchLatestRelease(mockFetch as typeof fetch, 1_060_000)

    expect(calls).toBe(1)
    expect(first.version).toBe('1.8.3')
    expect(first.dmgUrl).toBe(
      'https://github.com/Blinks44/monny/releases/download/v1.8.3/Monny.dmg',
    )
    expect(first.checksumsUrl).toBe(
      'https://github.com/Blinks44/monny/releases/download/v1.8.3/SHA256SUMS.txt',
    )
    expect(first.isFallback).toBe(false)
    expect(second).toEqual(first)
  })

  it('falls back gracefully when GitHub API returns an error', async () => {
    const mockFetch = vi
      .fn<typeof fetch>()
      .mockResolvedValue({ ok: false, status: 503 } as Response)
    const result = await fetchLatestRelease(mockFetch, 1_000_000)
    expect(result).toEqual(fallbackReleaseAssets())
    expect(result.isFallback).toBe(true)
  })
})
