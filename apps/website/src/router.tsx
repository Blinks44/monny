import { createRouter } from '@tanstack/react-router'
import { deLocalizeUrl, localizeUrl } from '@/integrations/i18n/paraglide/runtime'
import { routeTree } from './routeTree.gen'

export function getRouter() {
  return createRouter({
    routeTree,
    scrollRestoration: true,
    trailingSlash: 'always',
    rewrite: {
      input: ({ url }) => deLocalizeUrl(url),
      output: ({ url }) => localizeUrl(url),
    },
  })
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
