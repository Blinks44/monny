import handler from '@tanstack/react-start/server-entry'
import { site } from '@/config/site'
import { paraglideMiddleware } from '@/integrations/i18n/paraglide/server'
import { sitemap } from '@/integrations/seo'

export default {
  async fetch(request: Request): Promise<Response> {
    const { pathname } = new URL(request.url)
    if (pathname === '/robots.txt') {
      return new Response(`User-agent: *\nAllow: /\nSitemap: ${site.origin}/sitemap.xml\n`, {
        headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      })
    }
    if (pathname === '/sitemap.xml') {
      return new Response(sitemap(), {
        headers: { 'Content-Type': 'application/xml; charset=utf-8' },
      })
    }
    // Router rewrites localized URLs. Keep the original request for Start.
    return paraglideMiddleware(request, async () => {
      const response = await handler.fetch(request)
      const headers = new Headers(response.headers)
      headers.set('X-Content-Type-Options', 'nosniff')
      headers.set('Referrer-Policy', 'strict-origin-when-cross-origin')
      headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()')
      if (!site.indexingEnabled || response.status === 404) {
        headers.set('X-Robots-Tag', 'noindex, follow')
      }
      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers,
      })
    })
  },
}
