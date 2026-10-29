export const site = {
  name: 'Monny',
  origin: 'https://monny.moduix.dev',
  repository: 'https://github.com/blinks44/monny',
  releases: 'https://github.com/blinks44/monny/releases',
  author: { name: 'Sergey V.', x: 'https://x.com/TheBlinks182', xHandle: '@TheBlinks182' },
  // A versioned DMG stays valid after later releases; Sparkle updates the installed app.
  downloadUrl: 'https://github.com/blinks44/monny/releases/latest/download/Monny.dmg' as
    | string
    | null,
  indexingEnabled: true,
} as const
