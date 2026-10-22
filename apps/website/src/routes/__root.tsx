import { LocaleProvider } from '@moduix/react/locale'
import { createRootRoute, HeadContent, Outlet, Scripts } from '@tanstack/react-router'
import type { ReactNode } from 'react'
import appCss from '@/app.css?url'
import { PageShell } from '@/components/page-shell'
import { NotFoundPage } from '@/features/not-found/not-found-page'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { pageHead } from '@/integrations/seo'

export const Route = createRootRoute({
  head: () => {
    const seo = pageHead(getLocale(), true)
    return {
      ...seo,
      meta: [
        { charSet: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'theme-color', content: '#0b0b0d' },
        { name: 'color-scheme', content: 'dark' },
        ...seo.meta,
      ],
      links: [
        { rel: 'stylesheet', href: appCss },
        { rel: 'icon', type: 'image/png', href: '/app-icon.png' },
        { rel: 'apple-touch-icon', href: '/app-icon.png' },
        ...seo.links,
      ],
    }
  },
  shellComponent: RootDocument,
  component: Outlet,
  notFoundComponent: NotFoundPage,
})

function RootDocument({ children }: { children: ReactNode }) {
  const locale = getLocale()
  return (
    <html lang={locale} data-moduix-color-scheme="dark" data-moduix-theme="calm">
      <head>
        <HeadContent />
      </head>
      <body>
        <LocaleProvider locale={locale}>
          <PageShell>{children}</PageShell>
        </LocaleProvider>
        <Scripts />
      </body>
    </html>
  )
}
