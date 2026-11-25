import type { LocaleSeoContent } from './types'

export const enSeoContent: LocaleSeoContent = {
  alternatives: {
    'istat-menus': {
      slug: 'istat-menus',
      path: '/alternatives/istat-menus/',
      breadcrumbLabel: 'iStat Menus',
      metaTitle: 'Free iStat Menus Alternative for Apple Silicon (Swift 6) · Monny',
      metaDescription:
        'Compare Monny vs iStat Menus on Apple silicon: free MIT Swift 6 monitor with 7-day charts, rootless macOS 26.4+ battery limits, port/PID finder, and 22 AI quotas.',
      headline: 'A free, open-source iStat Menus alternative built for Apple silicon.',
      subtitle:
        'Monitor CPU P/E cores, memory, disk, network, Apple silicon SMC sensors, local ports, native battery charge limits, and 22 AI coding quotas in one free MIT SwiftUI app.',
      highlights: [
        {
          value: 'Swift 6 · MIT Free',
          label: 'Apple silicon native · no license fees, no telemetry',
        },
        {
          value: 'Zero Root Helper',
          label: 'Native macOS 26.4+ charge limit enforced by macOS',
        },
        {
          value: '22 AI Quotas + Ports',
          label: 'Built-in port/PID finder & opt-in local AI limits',
        },
      ],
      competitorColumn: 'ISTAT MENUS',
      rows: [
        {
          criterion: 'License & pricing',
          monny: '100% free & MIT open source on GitHub',
          other: 'Paid app or Setapp subscription',
        },
        {
          criterion: 'Battery charge limit',
          monny: 'Native macOS 26.4+ 80-100% cap with zero root helper',
          other: 'Battery stats only (no charge limiter)',
        },
        {
          criterion: 'Port & PID finder',
          monny: 'Search by port (localhost:3002), see working dir & quit task',
          other: 'Basic process list only (no port search)',
        },
        {
          criterion: 'AI coding quotas',
          monny: 'Opt-in local quota bars & reset timers for 22 AI tools',
          other: 'Not built in',
        },
        {
          criterion: '7-day history charts',
          monny: 'Full Swift Charts dashboard (1m-7d) with preserved sleep gaps',
          other: 'Compact dropdown graphs in menu bar',
        },
        {
          criterion: 'Privacy & telemetry',
          monny: 'Zero analytics, no accounts, all readings stay on Mac',
          other: 'Paid license activation & optional update checks',
        },
      ],
      chooseMonny: {
        label: 'RECOMMENDED FOR APPLE SILICON',
        title: 'Choose Monny when…',
        points: [
          'You want a free MIT Apple silicon monitor with 7-day history',
          'You also want rootless battery limits, port search & 22 AI quotas',
          'You prefer zero background daemons, accounts, or subscriptions',
        ],
      },
      stickWithOther: {
        label: 'WHEN ISTAT MENUS STILL FITS',
        title: 'Stick with iStat Menus when…',
        points: [
          'You need Intel Mac or older macOS (< 15) support',
          'You want manual fan-curve overrides or weather widgets',
          'You want highly granular custom menu bar graph themes',
        ],
      },
      steps: [
        {
          step: 'STEP 01',
          title: 'Install via Homebrew or DMG',
          description:
            'Run brew install --cask blinks44/tap/monny. No admin password, no system extension, no account required.',
        },
        {
          step: 'STEP 02',
          title: 'Pin compact metrics in menu bar',
          description:
            'Choose CPU, RAM, network, or battery items for your menu bar and open the full popover anytime with ⌥⌘M.',
        },
        {
          step: 'STEP 03',
          title: 'Optional: enable AI quotas & battery cap',
          description:
            'Turn on only the AI tools you use and set an 80% native charge limit on macOS 26.4+ without installing a root helper.',
        },
      ],
    },
    aldente: {
      slug: 'aldente',
      path: '/alternatives/aldente/',
      breadcrumbLabel: 'AlDente',
      metaTitle: 'Free AlDente Alternative Without a Root Helper (macOS 26.4+) · Monny',
      metaDescription:
        'Compare Monny vs AlDente: native macOS 26.4+ 80-100% battery charge limiting as a standard user with zero root daemons, plus full system monitoring and 22 AI quotas.',
      headline: 'A free AlDente alternative with zero root helper daemons.',
      subtitle:
        'Cap MacBook charging at 80-100% on macOS 26.4+ using Apple’s native charge-limit setting as a normal user. macOS keeps enforcing the cap even after Monny quits.',
      highlights: [
        {
          value: 'Zero Root Helper',
          label: 'No privileged LaunchDaemon, no kexts, no raw SMC writes',
        },
        {
          value: 'Persists After Quit',
          label: 'macOS 26.4+ enforces your 80-100% charge cap natively',
        },
        {
          value: 'Full Mac Monitor',
          label: 'Includes CPU, SMC thermals, ports & 22 AI quotas in one app',
        },
      ],
      competitorColumn: 'ALDENTE / BATFI',
      rows: [
        {
          criterion: 'Root privileges',
          monny: 'Standard user only - zero privileged root helpers',
          other: 'Requires privileged root helper daemon writing SMC keys',
        },
        {
          criterion: 'Works when app is closed',
          monny: 'Yes - macOS 26.4+ enforces the native limit after quit & reboot',
          other: 'Requires helper daemon running continuously in background',
        },
        {
          criterion: 'Price & license',
          monny: '100% free & MIT open source (no Pro paywall)',
          other: 'Freemium with paid Pro license or subscription for extra modes',
        },
        {
          criterion: 'Battery telemetry',
          monny: 'Health, cycle count, live watts, battery temp & charge alerts',
          other: 'Charge controls plus paid/Pro heat protection & calibration',
        },
        {
          criterion: 'Extra developer tools',
          monny: 'Menu bar telemetry, 7-day charts, port/PID finder & 22 AI quotas',
          other: 'Battery-only utility',
        },
        {
          criterion: 'macOS version scope',
          monny: 'Native limit on macOS 26.4+; read-only battery stats on macOS 15-26.3',
          other: 'Supports older macOS versions via privileged SMC helper',
        },
      ],
      chooseMonny: {
        label: 'RECOMMENDED ON MACOS 26.4+',
        title: 'Choose Monny when…',
        points: [
          'You are on Apple silicon with macOS 26.4+ and want a rootless 80-100% cap',
          'You want the charge limit to survive quitting the app and rebooting',
          'You want system monitoring, port search, and AI quotas in the same app',
        ],
      },
      stickWithOther: {
        label: 'WHEN ALDENTE STILL FITS',
        title: 'Stick with AlDente when…',
        points: [
          'You are still on macOS 15 through 26.3 and need active charge limiting today',
          'You want specialized modes like sailing mode, discharge, or calibration runs',
          'You use an Intel MacBook where Apple’s native 26.4+ API is unavailable',
        ],
      },
      steps: [
        {
          step: 'STEP 01',
          title: 'Install Monny cleanly',
          description:
            'Run brew install --cask blinks44/tap/monny or drag Monny.dmg into Applications. Zero admin prompts.',
        },
        {
          step: 'STEP 02',
          title: 'Set your 80-100% limit',
          description:
            'Open Battery settings in Monny on macOS 26.4+ and pick 80% (or any step up to 100%) using macOS’s native API.',
        },
        {
          step: 'STEP 03',
          title: 'Uninstall extra root helpers',
          description:
            'Once macOS holds your cap natively, you can retire separate battery daemons and keep one ~5 MB app in the menu bar.',
        },
      ],
    },
  },
  guides: {
    'ai-coding-quotas': {
      slug: 'ai-coding-quotas',
      path: '/guides/ai-coding-quotas/',
      breadcrumbLabel: '22 AI Coding Quotas',
      metaTitle: 'Track 22 AI Coding Quotas in the macOS Menu Bar · Monny',
      metaDescription:
        'Monitor remaining session and weekly quotas for Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf, and 16 more AI tools locally in your macOS menu bar.',
      headline: 'Track 22 AI coding quotas in your macOS menu bar.',
      subtitle:
        'Watch remaining session and weekly quotas for Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf, and 16 more tools right in your macOS menu bar. Off by default and 100% local.',
      secondaryCtaLabel: 'Also read: Port & PID finder',
      secondaryCtaTo: '/guides/port-pid-finder/',
      cardsTitle: 'Three developer workflows in one menu bar app',
      cards: [
        {
          label: 'VIBE CODING & AI',
          title: '22 AI Subscription Quotas',
          description: 'Know which agent still has headroom before starting a big task.',
          items: [
            'Claude Code · Codex · Cursor',
            'GitHub Copilot · Gemini · Windsurf',
            'JetBrains AI · Cline · Kimi · +13',
          ],
          footer: 'Opt-in · Off by default · 100% local',
        },
        {
          label: 'PORTS & PROCESSES',
          title: 'Ports & Runaway Processes',
          description: 'Skip lsof -i :3002 and find the exact folder holding a port.',
          items: [
            'Search: 3002 · localhost:3002',
            'Shows: PID · CWD · CPU% · RAM',
            'Action: Quit runaway task in 1 click',
          ],
          footer: 'Works right from ⌥⌘M popover',
        },
        {
          label: 'BATTERY & THERMALS',
          title: 'Overnight Charging & Heat',
          description: 'Keep MacBook battery healthy without installing root daemons.',
          items: [
            'Charge cap: 80% (macOS 26.4+)',
            'SMC sensors: Die temp · Fan RPM',
            'Alerts: High temp & low battery',
          ],
          footer: 'Enforced natively after Monny quits',
        },
      ],
      stepsTitle: 'How Monny stays fast and private',
      steps: [
        {
          step: '01 · INSTALL',
          title: 'Drop into Applications',
          description:
            'Install via Homebrew or DMG on Apple silicon (macOS 15+). No root helper or login required.',
        },
        {
          step: '02 · OPT IN',
          title: 'Pick your AI tools',
          description:
            'AI quota tracking is off by default. Enable only the providers you already sign into locally.',
        },
        {
          step: '03 · MENU BAR',
          title: 'Glance with ⌥⌘M',
          description:
            'See live quota bars, reset countdowns, open ports, and per-core load without switching windows.',
        },
        {
          step: '04 · TRACK RESETS',
          title: 'Smart alerts only',
          description:
            'Get notified for runaway CPU, memory pressure, high thermals, or charge limits - zero nagging.',
        },
      ],
      guarantees: [
        {
          title: 'Uses each tool’s own sign-in',
          description:
            'Monny reads AI quota status locally via each provider’s own CLI/session. No third-party proxy servers.',
        },
        {
          title: 'No root helper daemon',
          description:
            'Unlike legacy charge limiters, Monny uses macOS 26.4+ native charge limit APIs as a standard user.',
        },
        {
          title: 'Zero analytics or accounts',
          description:
            'All telemetry and 7-day history stay inside local storage on your Mac. Nothing is uploaded.',
        },
      ],
    },
    'port-pid-finder': {
      slug: 'port-pid-finder',
      path: '/guides/port-pid-finder/',
      breadcrumbLabel: 'Ports & Processes',
      metaTitle: 'Find Open Ports & Kill Processes on macOS Without lsof · Monny',
      metaDescription:
        'Search listening localhost ports by number or URL, inspect the exact PID and working directory, and quit stuck dev servers from the macOS menu bar in one click.',
      headline: 'Find open ports and stuck dev servers without lsof.',
      subtitle:
        'Hit ⌥⌘M, type 3000 or localhost:5432, inspect the process PID, working folder, CPU and RAM usage, and stop a runaway task cleanly without digging through terminal flags.',
      secondaryCtaLabel: 'Also read: 22 AI coding quotas',
      secondaryCtaTo: '/guides/ai-coding-quotas/',
      cardsTitle: 'Everything you need when a port is already in use',
      cards: [
        {
          label: 'INSTANT PORT SEARCH',
          title: 'Type a Port or Local URL',
          description:
            'Stop memorizing lsof -nP -iTCP:3000 -sTCP:LISTEN every time a server clashes.',
          items: [
            'Match by port: 3000, 5173, 5432, 8080',
            'Match by URL: localhost:3002',
            'Filter by process name or PID',
          ],
          footer: 'Instant search inside ⌥⌘M popover',
        },
        {
          label: 'REAL CONTEXT',
          title: 'See Which Repo Holds the Port',
          description:
            'Identify whether port 3000 belongs to an old worktree or a background agent.',
          items: [
            'Working directory (CWD) path',
            'Live CPU% and memory footprint',
            'Parent process & command visibility',
          ],
          footer: 'No guesswork between multiple Node or Go servers',
        },
        {
          label: 'SAFE TERMINATION',
          title: 'Quit Runaway Tasks Cleanly',
          description: 'Stop orphaned dev servers or hung watchers directly from the menu bar.',
          items: [
            'One-click stop for listening tasks',
            'Spot high-CPU background loops fast',
            'Works alongside Docker & local DBs',
          ],
          footer: 'Zero root daemon · standard macOS user permissions',
        },
      ],
      stepsTitle: 'From “EADDRINUSE” to clean port in seconds',
      steps: [
        {
          step: '01 · OPEN',
          title: 'Press ⌥⌘M anywhere',
          description:
            'Summon the Monny menu bar popover over your editor or terminal without losing focus.',
        },
        {
          step: '02 · SEARCH',
          title: 'Type the port number',
          description:
            'Enter 3000, 3002, or localhost:8080 to isolate the exact listening process immediately.',
        },
        {
          step: '03 · INSPECT',
          title: 'Check PID & project folder',
          description:
            'Verify the process name, working directory, CPU, and memory before deciding to stop it.',
        },
        {
          step: '04 · CLEAN UP',
          title: 'Stop and restart cleanly',
          description:
            'Quit the stuck process in one click and return straight to your terminal or AI coding agent.',
        },
      ],
      guarantees: [
        {
          title: 'Read-only until you click Quit',
          description:
            'Monny never terminates background processes automatically. You always inspect the PID and folder first.',
        },
        {
          title: 'Native Swift performance',
          description:
            'Built in Swift 6 for Apple silicon (~5 MB app) with negligible idle footprint compared to Electron monitors.',
        },
        {
          title: 'Pairs with Hearth for full dev envs',
          description:
            'Use Monny for live macOS telemetry, ports, battery, and AI quotas, and Hearth for runtimes, Docker, K8s, and AI configs.',
        },
      ],
    },
  },
}
