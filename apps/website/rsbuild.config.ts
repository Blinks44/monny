import { builtinModules } from 'node:module'
import { paraglideRspackPlugin } from '@inlang/paraglide-js'
import { defineConfig, type RsbuildPlugin } from '@rsbuild/core'
import { pluginReact } from '@rsbuild/plugin-react'
import { tanstackStart } from '@tanstack/react-start/plugin/rsbuild'

// URL prefix of every language except English, which lives at `/`.
const prefixes: [locale: string, prefix: string][] = [
  ['ru', '/ru'],
  ['de', '/de'],
  ['fr', '/fr'],
  ['es', '/es'],
  ['zh-Hans', '/zh'],
]
const rest = '/:path(.*)?'

// Production runs the server on Cloudflare Workers: build it for a worker, keeping the
// Node built-ins that the Workers runtime provides (nodejs_compat) as imports.
const workerServer: RsbuildPlugin = {
  name: 'monny:worker-server',
  setup(api) {
    if (api.context.action !== 'build') return
    api.modifyEnvironmentConfig((config, { name, mergeEnvironmentConfig }) => {
      if (name !== 'ssr') return config
      return mergeEnvironmentConfig(config, {
        output: {
          target: 'web-worker',
          module: true,
          filename: { js: '[name].js' },
          // Minify CSS like the client build, so `?url` stylesheets get the client's file names.
          minify: { js: false, css: true },
          externals: [/^node:/, ...builtinModules],
        },
        // Keep the entry's default export: it is the Worker's fetch handler.
        tools: { rspack: { output: { library: { type: 'module' } } } },
      })
    })
  },
}

export default defineConfig({
  server: { port: 3000 },
  plugins: [pluginReact(), tanstackStart({ srcDirectory: 'src' }), workerServer],
  tools: {
    rspack: {
      plugins: [
        paraglideRspackPlugin({
          project: './project.inlang',
          outdir: './src/paraglide',
          outputStructure: 'message-modules',
          // The URL alone decides the language.
          strategy: ['url', 'baseLocale'],
          urlPatterns: [
            { pattern: '/', localized: [...prefixes, ['en', '/']] },
            { pattern: rest, localized: [...prefixes.map(([locale, prefix]): [string, string] => [locale, prefix + rest]), ['en', rest]] },
          ],
        }),
      ],
    },
  },
})
