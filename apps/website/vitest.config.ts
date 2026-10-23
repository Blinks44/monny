import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitest/config'
import { imagetools } from 'vite-imagetools'

export default defineConfig({
  plugins: [imagetools()],
  resolve: { alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) } },
  test: {
    include: ['src/test/**/*.test.ts'],
    environment: 'node',
    server: { deps: { inline: ['@moduix/react'] } },
  },
})
