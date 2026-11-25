import type { LocaleSeoContent } from './types'

export const deSeoContent: LocaleSeoContent = {
  alternatives: {
    'istat-menus': {
      slug: 'istat-menus',
      path: '/alternatives/istat-menus/',
      breadcrumbLabel: 'iStat Menus',
      metaTitle: 'Kostenlose iStat-Menus-Alternative für Apple Silicon (Swift 6) · Monny',
      metaDescription:
        'Vergleiche Monny und iStat Menus auf Apple Silicon: kostenloser MIT-Swift-6-Monitor mit 7-Tage-Charts, rootlosem macOS-26.4+-Ladelimit, Port-/PID-Finder und 22 KI-Kontingenten.',
      headline: 'Eine kostenlose Open-Source-Alternative zu iStat Menus für Apple Silicon.',
      subtitle:
        'Überwache CPU-P/E-Kerne, RAM, Disk, Netzwerk, Apple-Silicon-SMC-Sensoren, lokale Ports, native Ladelimits und 22 KI-Coding-Kontingente in einer kostenlosen MIT-SwiftUI-App.',
      highlights: [
        {
          value: 'Swift 6 · MIT Frei',
          label: 'Apple-Silicon-nativ · keine Lizenzkosten, keine Telemetrie',
        },
        {
          value: 'Ohne Root-Helper',
          label: 'Natives macOS-26.4+-Ladelimit direkt vom System erzwungen',
        },
        {
          value: '22 KI-Quotas + Ports',
          label: 'Integrierter Port-/PID-Finder & lokale KI-Limits nach Bedarf',
        },
      ],
      competitorColumn: 'ISTAT MENUS',
      rows: [
        {
          criterion: 'Lizenz & Preis',
          monny: '100 % kostenlos & MIT Open Source auf GitHub',
          other: 'Kostenpflichtige App oder Setapp-Abo',
        },
        {
          criterion: 'Akku-Ladelimit',
          monny: 'Natives macOS-26.4+-Limit (80-100 %) ohne Root-Helper',
          other: 'Nur Akkustatistiken (kein Ladelimit)',
        },
        {
          criterion: 'Port- & PID-Finder',
          monny: 'Suche nach Port (localhost:3002), Arbeitsordner & Prozess beenden',
          other: 'Nur einfache Prozessliste (keine Portsuche)',
        },
        {
          criterion: 'KI-Coding-Kontingente',
          monny: 'Optionale lokale Balken & Reset-Timer für 22 KI-Tools',
          other: 'Nicht enthalten',
        },
        {
          criterion: '7-Tage-Verlauf',
          monny: 'Volles Swift-Charts-Dashboard (1m-7d) mit erhaltenen Ruhezustandslücken',
          other: 'Kompakte Dropdown-Graphen in der Menüleiste',
        },
        {
          criterion: 'Datenschutz & Telemetrie',
          monny: 'Keine Analytik, kein Konto, alle Messwerte bleiben auf dem Mac',
          other: 'Lizenzaktivierung & optionale Update-Prüfungen',
        },
      ],
      chooseMonny: {
        label: 'EMPFOHLEN FÜR APPLE SILICON',
        title: 'Wähle Monny, wenn…',
        points: [
          'Du einen kostenlosen MIT-Monitor für Apple Silicon mit 7-Tage-Verlauf willst',
          'Du außerdem rootlose Ladelimits, Portsuche & 22 KI-Kontingente möchtest',
          'Du keine Hintergrund-Daemons, Konten oder Abos installieren willst',
        ],
      },
      stickWithOther: {
        label: 'WANN ISTAT MENUS WEITERHIN PASST',
        title: 'Bleib bei iStat Menus, wenn…',
        points: [
          'Du Intel-Macs oder älteres macOS (< 15) unterstützen musst',
          'Du manuelle Lüfterkurven oder Wetter-Widgets in der Menüleiste brauchst',
          'Du sehr feingranulare Menüleisten-Graph-Themes anpassen willst',
        ],
      },
      steps: [
        {
          step: 'SCHRITT 01',
          title: 'Per Homebrew oder DMG installieren',
          description:
            'Führe brew install --cask blinks44/tap/monny aus. Kein Admin-Passwort, keine Systemerweiterung, kein Konto.',
        },
        {
          step: 'SCHRITT 02',
          title: 'Kompakte Metriken anpinnen',
          description:
            'Wähle CPU, RAM, Netzwerk oder Akku für deine Menüleiste und öffne das Popover jederzeit mit ⌥⌘M.',
        },
        {
          step: 'SCHRITT 03',
          title: 'Optional: KI-Kontingente & Ladelimit aktivieren',
          description:
            'Schalte nur deine genutzten KI-Tools ein und setze auf macOS 26.4+ ein natives 80-%-Ladelimit ohne Root-Helper.',
        },
      ],
    },
    aldente: {
      slug: 'aldente',
      path: '/alternatives/aldente/',
      breadcrumbLabel: 'AlDente',
      metaTitle: 'Kostenlose AlDente-Alternative ohne Root-Helper (macOS 26.4+) · Monny',
      metaDescription:
        'Vergleiche Monny und AlDente: natives macOS-26.4+-Ladelimit (80-100 %) als normaler Benutzer ohne Root-Daemons plus voller Mac-Monitor und 22 KI-Kontingente.',
      headline: 'Eine kostenlose AlDente-Alternative ganz ohne Root-Helper.',
      subtitle:
        'Begrenze den MacBook-Akku auf macOS 26.4+ über Apples native Ladelimit-Einstellung auf 80-100 % als normaler Benutzer. macOS hält das Limit auch nach dem Beenden von Monny.',
      highlights: [
        {
          value: 'Ohne Root-Helper',
          label: 'Kein privilegierter LaunchDaemon, keine Kexts, keine SMC-Writes',
        },
        {
          value: 'Bleibt nach Quit aktiv',
          label: 'macOS 26.4+ setzt dein 80-100-%-Limit nativ durch',
        },
        {
          value: 'Kompletter Mac-Monitor',
          label: 'Inklusive CPU, SMC-Sensoren, Ports & 22 KI-Kontingenten',
        },
      ],
      competitorColumn: 'ALDENTE / BATFI',
      rows: [
        {
          criterion: 'Root-Rechte',
          monny: 'Standardbenutzer - null privilegierte Root-Helper',
          other: 'Erfordert privilegierten Root-Daemon zum Schreiben von SMC-Keys',
        },
        {
          criterion: 'Aktiv nach Beenden',
          monny: 'Ja - macOS 26.4+ hält das native Limit nach Quit & Neustart',
          other: 'Erfordert dauerhaft laufenden Hintergrund-Daemon',
        },
        {
          criterion: 'Preis & Lizenz',
          monny: '100 % kostenlos & MIT Open Source (keine Pro-Paywall)',
          other: 'Freemium mit kostenpflichtiger Pro-Lizenz oder Abo',
        },
        {
          criterion: 'Akku-Telemetrie',
          monny: 'Zustand, Zyklen, Wattzahl, Akkutemperatur & Ladewarnungen',
          other: 'Ladesteuerung plus kostenpflichtiger Hitzeschutz & Kalibrierung',
        },
        {
          criterion: 'Zusätzliche Dev-Tools',
          monny: 'Menüleisten-Monitor, 7-Tage-Charts, Port-/PID-Finder & 22 KI-Quotas',
          other: 'Reines Akku-Tool',
        },
        {
          criterion: 'macOS-Versionen',
          monny: 'Natives Limit ab macOS 26.4+; Read-only-Akkudaten auf macOS 15-26.3',
          other: 'Unterstützt ältere macOS-Versionen über Root-SMC-Helper',
        },
      ],
      chooseMonny: {
        label: 'EMPFOHLEN AB MACOS 26.4+',
        title: 'Wähle Monny, wenn…',
        points: [
          'Du auf Apple Silicon mit macOS 26.4+ ein rootloses 80-100-%-Limit möchtest',
          'Das Limit auch nach dem Schließen der App und Neustarts greifen soll',
          'Du Systemmonitoring, Portsuche und KI-Kontingente in einer App willst',
        ],
      },
      stickWithOther: {
        label: 'WANN ALDENTE WEITERHIN PASST',
        title: 'Bleib bei AlDente, wenn…',
        points: [
          'Du noch auf macOS 15 bis 26.3 bist und heute ein aktives Limit brauchst',
          'Du Spezialmodi wie Sailing Mode, Entladen oder Kalibrierung nutzt',
          'Du ein Intel-MacBook ohne Apples native 26.4+-API verwendest',
        ],
      },
      steps: [
        {
          step: 'SCHRITT 01',
          title: 'Monny sauber installieren',
          description:
            'Führe brew install --cask blinks44/tap/monny aus oder ziehe Monny.dmg in Programme. Keine Admin-Abfragen.',
        },
        {
          step: 'SCHRITT 02',
          title: '80-100-%-Limit festlegen',
          description:
            'Öffne die Akku-Einstellungen in Monny auf macOS 26.4+ und wähle 80 % über Apples native API.',
        },
        {
          step: 'SCHRITT 03',
          title: 'Alte Root-Helper entfernen',
          description:
            'Sobald macOS dein Limit nativ hält, kannst du separate Akku-Daemons deinstallieren.',
        },
      ],
    },
  },
  guides: {
    'ai-coding-quotas': {
      slug: 'ai-coding-quotas',
      path: '/guides/ai-coding-quotas/',
      breadcrumbLabel: '22 KI-Kontingente',
      metaTitle: '22 KI-Coding-Kontingente in der macOS-Menüleiste verfolgen · Monny',
      metaDescription:
        'Überwache verbleibende Sitzungs- und Wochenkontingente für Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf und 16 weitere Tools lokal in der macOS-Menüleiste.',
      headline: 'Verfolge 22 KI-Coding-Kontingente in deiner macOS-Menüleiste.',
      subtitle:
        'Sieh verbleibende Sitzungs- und Wochenlimits für Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf und 16 weitere Tools direkt in der Menüleiste. Standardmäßig aus und 100 % lokal.',
      secondaryCtaLabel: 'Auch lesen: Port- & PID-Finder',
      secondaryCtaTo: '/guides/port-pid-finder/',
      cardsTitle: 'Drei Entwickler-Workflows in einer Menüleisten-App',
      cards: [
        {
          label: 'VIBE CODING & KI',
          title: '22 KI-Abo-Kontingente',
          description: 'Sieh vor großen Aufgaben sofort, welcher Agent noch Spielraum hat.',
          items: [
            'Claude Code · Codex · Cursor',
            'GitHub Copilot · Gemini · Windsurf',
            'JetBrains AI · Cline · Kimi · +13',
          ],
          footer: 'Opt-in · Standardmäßig aus · 100 % lokal',
        },
        {
          label: 'PORTS & PROZESSE',
          title: 'Ports & hängende Prozesse',
          description:
            'Spare dir lsof -i :3002 und erkenne sofort den Projektordner hinter dem Port.',
          items: [
            'Suche: 3002 · localhost:3002',
            'Zeigt: PID · CWD · CPU% · RAM',
            'Aktion: Prozess mit 1 Klick beenden',
          ],
          footer: 'Direkt im ⌥⌘M-Popover nutzbar',
        },
        {
          label: 'AKKU & THERMIK',
          title: 'Laden über Nacht & Hitze',
          description: 'Schone deinen MacBook-Akku ohne Root-Daemons.',
          items: [
            'Ladelimit: 80 % (macOS 26.4+)',
            'SMC-Sensoren: Chip-Temp · Lüfter-RPM',
            'Alarme: Hohe Temp & niedriger Akku',
          ],
          footer: 'Bleibt nach Beenden von Monny nativ aktiv',
        },
      ],
      stepsTitle: 'So bleibt Monny schnell und privat',
      steps: [
        {
          step: '01 · INSTALLIEREN',
          title: 'In Programme legen',
          description:
            'Per Homebrew oder DMG auf Apple Silicon (macOS 15+) installieren. Kein Root-Helper oder Login nötig.',
        },
        {
          step: '02 · OPT-IN',
          title: 'KI-Tools auswählen',
          description:
            'KI-Tracking ist standardmäßig aus. Aktiviere nur die Anbieter, bei denen du lokal bereits angemeldet bist.',
        },
        {
          step: '03 · MENÜLEISTE',
          title: 'Blick per ⌥⌘M',
          description:
            'Live-Kontingente, Reset-Countdowns, offene Ports und Kernlast ohne Fensterwechsel prüfen.',
        },
        {
          step: '04 · RUHE BEWAHREN',
          title: 'Nur sinnvolle Warnungen',
          description:
            'Hinweise bei Amok-CPU, Speicherdruck, Überhitzung oder Ladelimit - ganz ohne Generve.',
        },
      ],
      guarantees: [
        {
          title: 'Nutzt die eigene Anmeldung jedes Tools',
          description:
            'Monny liest Kontingente lokal über CLI/Sitzung des jeweiligen Anbieters. Keine Drittanbieter-Proxys.',
        },
        {
          title: 'Kein Root-Helper-Daemon',
          description:
            'Anders als klassische Akku-Limiter nutzt Monny die native macOS-26.4+-API als normaler Benutzer.',
        },
        {
          title: 'Keine Analytik oder Konten',
          description:
            'Alle Messdaten und 7-Tage-Verläufe bleiben lokal auf deinem Mac. Nichts wird hochgeladen.',
        },
      ],
    },
    'port-pid-finder': {
      slug: 'port-pid-finder',
      path: '/guides/port-pid-finder/',
      breadcrumbLabel: 'Ports & Prozesse',
      metaTitle: 'Offene Ports & Prozesse auf macOS ohne lsof finden · Monny',
      metaDescription:
        'Suche lauschende Localhost-Ports nach Nummer oder URL, prüfe PID und Arbeitsordner und beende blockierende Dev-Server direkt in der macOS-Menüleiste.',
      headline: 'Finde offene Ports und hängende Dev-Server ohne lsof.',
      subtitle:
        'Drücke ⌥⌘M, tippe 3000 oder localhost:5432 ein, prüfe PID, Arbeitsverzeichnis, CPU und RAM und stoppe hängende Prozesse sauber ohne Terminal-Flags.',
      secondaryCtaLabel: 'Auch lesen: 22 KI-Kontingente',
      secondaryCtaTo: '/guides/ai-coding-quotas/',
      cardsTitle: 'Alles, was du bei belegten Ports brauchst',
      cards: [
        {
          label: 'SOFORTIGE PORTSUCHE',
          title: 'Port oder lokale URL eintippen',
          description: 'Schluss mit lsof -nP -iTCP:3000 -sTCP:LISTEN bei jedem Portkonflikt.',
          items: [
            'Nach Port: 3000, 5173, 5432, 8080',
            'Nach URL: localhost:3002',
            'Nach Prozessname oder PID filtern',
          ],
          footer: 'Sofortsuche direkt im ⌥⌘M-Popover',
        },
        {
          label: 'ECHTER KONTEXT',
          title: 'Sieh, welches Repo den Port hält',
          description: 'Erkenne sofort, ob Port 3000 zu einem alten Worktree oder Agenten gehört.',
          items: [
            'Pfad zum Arbeitsverzeichnis (CWD)',
            'Live-CPU% und Speicherverbrauch',
            'Elternprozess & Startbefehl sichtbar',
          ],
          footer: 'Kein Rätselraten bei mehreren Node- oder Go-Servern',
        },
        {
          label: 'SICHERES BEENDEN',
          title: 'Hängende Aufgaben sauber stoppen',
          description:
            'Beende verwaiste Dev-Server oder blockierte Watcher direkt aus der Menüleiste.',
          items: [
            '1-Klick-Stopp für lauschende Prozesse',
            'CPU-Ausreißer sofort erkennen',
            'Funktioniert neben Docker & lokalen DBs',
          ],
          footer: 'Kein Root-Daemon · normale macOS-Benutzerrechte',
        },
      ],
      stepsTitle: 'Von EADDRINUSE zum freien Port in Sekunden',
      steps: [
        {
          step: '01 · ÖFFNEN',
          title: 'Überall ⌥⌘M drücken',
          description:
            'Öffne das Monny-Popover über Editor oder Terminal, ohne den Fokus zu verlieren.',
        },
        {
          step: '02 · SUCHEN',
          title: 'Portnummer eintippen',
          description:
            'Gib 3000, 3002 oder localhost:8080 ein, um den exakten Prozess sofort zu isolieren.',
        },
        {
          step: '03 · PRÜFEN',
          title: 'PID & Projektordner kontrollieren',
          description:
            'Prüfe Prozessname, Arbeitsverzeichnis, CPU und RAM, bevor du den Task beendest.',
        },
        {
          step: '04 · AUFRÄUMEN',
          title: 'Stoppen und sauber neu starten',
          description:
            'Beende den blockierenden Prozess mit einem Klick und kehre direkt ins Terminal zurück.',
        },
      ],
      guarantees: [
        {
          title: 'Nur lesend bis zu deinem Klick',
          description:
            'Monny beendet nie Prozesse automatisch. Du siehst immer zuerst PID und Projektordner.',
        },
        {
          title: 'Native Swift-Performance',
          description:
            'In Swift 6 für Apple Silicon (~5 MB) gebaut, mit minimaler Grundlast statt Electron-Overhead.',
        },
        {
          title: 'Perfektes Duo mit Hearth',
          description:
            'Monny überwacht macOS-Telemetrie, Ports, Akku und KI-Quotas, während Hearth Runtimes, Docker, K8s und KI-Configs pflegt.',
        },
      ],
    },
  },
}
