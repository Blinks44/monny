export const site = {
  name: 'Monny',
  origin: 'https://monny.moduix.dev',
  repository: 'https://github.com/blinks44/monny',
  releases: 'https://github.com/blinks44/monny/releases',
  // A versioned DMG stays valid after later releases; Sparkle updates the installed app.
  downloadUrl: 'https://github.com/blinks44/monny/releases/download/v1.1.0/Monny-1.1.0-63.dmg' as
    | string
    | null,
  indexingEnabled: true,
} as const
