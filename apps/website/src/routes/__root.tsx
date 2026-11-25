import { LocaleProvider } from '@moduix/react/locale'
import { createRootRoute, HeadContent, Link, Outlet, Scripts } from '@tanstack/react-router'
import type { ReactNode } from 'react'
import appCss from '@/app.css?url'
import type { Locale } from '@/config/locales'
import * as m from '@/integrations/i18n/paraglide/messages'
import { getLocale } from '@/integrations/i18n/paraglide/runtime'
import { pageHead } from '@/integrations/seo'
import { themeInitScript } from '@/lib/theme'

export const Route = createRootRoute({
  head: ({ matches }) => {
    const locale = getLocale() as Locale
    const isNotFound = matches.length <= 1
    const fallbackSeo = isNotFound ? pageHead(locale, { notFound: true }) : null

    return {
      meta: [
        { charSet: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'theme-color', content: '#fbfbfd', media: '(prefers-color-scheme: light)' },
        { name: 'theme-color', content: '#111114', media: '(prefers-color-scheme: dark)' },
        ...(fallbackSeo?.meta ?? []),
      ],
      links: [
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossOrigin: 'anonymous' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600;700&display=swap',
        },
        { rel: 'stylesheet', href: appCss },
        { rel: 'icon', type: 'image/png', href: '/app-icon.png' },
        { rel: 'apple-touch-icon', href: '/app-icon.png' },
      ],
      scripts: [{ children: themeInitScript }],
    }
  },
  shellComponent: RootDocument,
  component: Outlet,
  notFoundComponent: NotFoundPage,
})

function RootDocument({ children }: { children: ReactNode }) {
  const locale = getLocale() as Locale
  return (
    <html
      lang={locale}
      data-moduix-color-scheme="light"
      data-moduix-theme="calm"
      data-theme="light"
      suppressHydrationWarning
    >
      <head>
        <HeadContent />
      </head>
      <body>
        <LocaleProvider locale={locale}>{children}</LocaleProvider>
        <Scripts />
      </body>
    </html>
  )
}

function NotFoundPage() {
  return (
    <main
      className="container"
      style={{
        minHeight: '72vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        gap: '1rem',
      }}
    >
      <img src="/app-icon.png" alt="Monny" width={56} height={56} className="final-cta-icon" />
      <h1 className="section-title">{m.notFoundHeading()}</h1>
      <p className="section-subtitle">{m.notFoundDescription()}</p>
      <Link to="/" className="btn-monny-primary">
        {m.notFoundBack()}
      </Link>
    </main>
  )
}
