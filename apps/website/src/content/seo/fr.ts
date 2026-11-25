import type { LocaleSeoContent } from './types'

export const frSeoContent: LocaleSeoContent = {
  alternatives: {
    'istat-menus': {
      slug: 'istat-menus',
      path: '/alternatives/istat-menus/',
      breadcrumbLabel: 'iStat Menus',
      metaTitle: 'Alternative gratuite à iStat Menus pour Apple Silicon (Swift 6) · Monny',
      metaDescription:
        'Comparez Monny et iStat Menus sur Apple Silicon : moniteur MIT gratuit en Swift 6 avec graphiques 7 jours, limite de charge sans root macOS 26.4+, ports/PID et 22 quotas IA.',
      headline: 'Une alternative gratuite et open source à iStat Menus pour Apple Silicon.',
      subtitle:
        'Surveillez cœurs P/E CPU, mémoire, disque, réseau, capteurs SMC Apple Silicon, ports locaux, limite de batterie native et 22 quotas IA dans une app SwiftUI gratuite sous MIT.',
      highlights: [
        {
          value: 'Swift 6 · MIT Gratuit',
          label: 'Natif Apple Silicon · sans licence payante ni télémétrie',
        },
        {
          value: 'Zéro helper root',
          label: 'Limite native macOS 26.4+ appliquée directement par macOS',
        },
        {
          value: '22 quotas IA + ports',
          label: 'Recherche ports/PID intégrée et quotas IA locaux optionnels',
        },
      ],
      competitorColumn: 'ISTAT MENUS',
      rows: [
        {
          criterion: 'Licence et prix',
          monny: '100 % gratuit et open source MIT sur GitHub',
          other: 'Application payante ou abonnement Setapp',
        },
        {
          criterion: 'Limite de charge batterie',
          monny: 'Plafond natif macOS 26.4+ (80-100 %) sans helper root',
          other: 'Statistiques batterie uniquement (pas de limiteur)',
        },
        {
          criterion: 'Recherche ports & PID',
          monny: 'Recherche par port (localhost:3002), dossier actif et arrêt en 1 clic',
          other: 'Liste de processus basique (sans recherche par port)',
        },
        {
          criterion: 'Quotas IA de code',
          monny: 'Barres locales optionnelles et comptes à rebours pour 22 outils IA',
          other: 'Non intégré',
        },
        {
          criterion: 'Historique 7 jours',
          monny: 'Tableau Swift Charts complet (1m-7j) préservant les pauses de veille',
          other: 'Mini-graphiques compacts dans le menu déroulant',
        },
        {
          criterion: 'Confidentialité & télémétrie',
          monny: 'Zéro analytique, sans compte, tout reste sur votre Mac',
          other: 'Activation de licence payante et vérifications de mises à jour',
        },
      ],
      chooseMonny: {
        label: 'RECOMMANDÉ POUR APPLE SILICON',
        title: 'Choisissez Monny si…',
        points: [
          'Vous voulez un moniteur MIT gratuit Apple Silicon avec historique 7 jours',
          'Vous voulez aussi limite de batterie sans root, ports et 22 quotas IA',
          'Vous préférez zéro démon en arrière-plan, sans compte ni abonnement',
        ],
      },
      stickWithOther: {
        label: 'QUAND ISTAT MENUS RESTE PERTINENT',
        title: 'Gardez iStat Menus si…',
        points: [
          'Vous utilisez un Mac Intel ou macOS antérieur à 15',
          'Vous voulez des courbes manuelles de ventilateurs ou widgets météo',
          'Vous tenez à personnaliser finement les thèmes de graphes de la barre',
        ],
      },
      steps: [
        {
          step: 'ÉTAPE 01',
          title: 'Installer via Homebrew ou DMG',
          description:
            'Lancez brew install --cask blinks44/tap/monny. Aucun mot de passe admin, extension système ni compte.',
        },
        {
          step: 'ÉTAPE 02',
          title: 'Épingler des métriques compactes',
          description:
            'Choisissez CPU, RAM, réseau ou batterie pour la barre des menus et ouvrez le popover à tout moment avec ⌥⌘M.',
        },
        {
          step: 'ÉTAPE 03',
          title: 'Optionnel : activer quotas IA & limite batterie',
          description:
            'Activez uniquement vos outils IA et fixez une limite native à 80 % sur macOS 26.4+ sans helper root.',
        },
      ],
    },
    aldente: {
      slug: 'aldente',
      path: '/alternatives/aldente/',
      breadcrumbLabel: 'AlDente',
      metaTitle: 'Alternative gratuite à AlDente sans helper root (macOS 26.4+) · Monny',
      metaDescription:
        'Comparez Monny et AlDente : limite de charge native 80-100 % sur macOS 26.4+ sans démon root, plus moniteur système complet et 22 quotas IA.',
      headline: 'Une alternative gratuite à AlDente sans démon root.',
      subtitle:
        'Plafonnez la charge du MacBook à 80-100 % sur macOS 26.4+ grâce au réglage natif Apple en utilisateur standard. macOS maintient le plafond même après fermeture de Monny.',
      highlights: [
        {
          value: 'Zéro helper root',
          label: 'Aucun LaunchDaemon privilégié, aucun kext, aucune écriture SMC brute',
        },
        {
          value: 'Persiste après fermeture',
          label: 'macOS 26.4+ applique votre limite 80-100 % nativement',
        },
        {
          value: 'Moniteur Mac complet',
          label: 'Inclut CPU, capteurs SMC, ports et 22 quotas IA dans une seule app',
        },
      ],
      competitorColumn: 'ALDENTE / BATFI',
      rows: [
        {
          criterion: 'Privilèges root',
          monny: 'Utilisateur standard uniquement - zéro helper root',
          other: 'Exige un démon root privilégié écrivant dans le SMC',
        },
        {
          criterion: 'Actif une fois fermé',
          monny: 'Oui - macOS 26.4+ maintient la limite après fermeture et redémarrage',
          other: 'Nécessite un démon actif en permanence en arrière-plan',
        },
        {
          criterion: 'Prix et licence',
          monny: '100 % gratuit et open source MIT (aucun paywall Pro)',
          other: 'Freemium avec licence Pro payante ou abonnement',
        },
        {
          criterion: 'Télémétrie batterie',
          monny: 'Santé, cycles, puissance en watts, température et alertes',
          other: 'Contrôles de charge plus protection thermique et calibration payantes',
        },
        {
          criterion: 'Outils développeur inclus',
          monny: 'Moniteur barre de menus, graphes 7j, ports/PID et 22 quotas IA',
          other: 'Utilitaire dédié uniquement à la batterie',
        },
        {
          criterion: 'Versions macOS',
          monny: 'Limite native dès macOS 26.4+ ; lecture seule sur macOS 15-26.3',
          other: 'Supporte d’anciens macOS via helper SMC privilégié',
        },
      ],
      chooseMonny: {
        label: 'RECOMMANDÉ SUR MACOS 26.4+',
        title: 'Choisissez Monny si…',
        points: [
          'Vous êtes sur Apple Silicon avec macOS 26.4+ et voulez un plafond 80-100 % sans root',
          'Vous voulez que la limite survive à la fermeture et aux redémarrages',
          'Vous souhaitez réunir batterie, suivi système, ports et quotas IA',
        ],
      },
      stickWithOther: {
        label: 'QUAND ALDENTE RESTE PERTINENT',
        title: 'Gardez AlDente si…',
        points: [
          'Vous êtes encore sur macOS 15 à 26.3 et avez besoin d’une limite active aujourd’hui',
          'Vous utilisez des modes avancés comme sailing mode, décharge ou calibration',
          'Vous utilisez un MacBook Intel sans l’API native macOS 26.4+',
        ],
      },
      steps: [
        {
          step: 'ÉTAPE 01',
          title: 'Installer Monny proprement',
          description:
            'Lancez brew install --cask blinks44/tap/monny ou glissez Monny.dmg dans Applications. Zéro invite admin.',
        },
        {
          step: 'ÉTAPE 02',
          title: 'Régler votre plafond 80-100 %',
          description:
            'Ouvrez les réglages Batterie dans Monny sur macOS 26.4+ et choisissez 80 % via l’API native macOS.',
        },
        {
          step: 'ÉTAPE 03',
          title: 'Retirer les anciens helpers root',
          description:
            'Une fois le plafond géré nativement par macOS, retirez les démons séparés et gardez une seule app de ~5 Mo.',
        },
      ],
    },
  },
  guides: {
    'ai-coding-quotas': {
      slug: 'ai-coding-quotas',
      path: '/guides/ai-coding-quotas/',
      breadcrumbLabel: '22 quotas IA',
      metaTitle: 'Suivez 22 quotas IA dans la barre des menus macOS · Monny',
      metaDescription:
        'Surveillez les quotas de session et hebdomadaires de Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf et 16 autres outils localement dans la barre des menus.',
      headline: 'Suivez 22 quotas IA directement dans votre barre des menus macOS.',
      subtitle:
        'Gardez un œil sur vos limites de session et hebdomadaires pour Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf et 16 autres outils. Désactivé par défaut et 100 % local.',
      secondaryCtaLabel: 'À lire aussi : Recherche ports & PID',
      secondaryCtaTo: '/guides/port-pid-finder/',
      cardsTitle: 'Trois workflows développeur dans une app de barre des menus',
      cards: [
        {
          label: 'VIBE CODING & IA',
          title: '22 quotas d’abonnements IA',
          description: 'Sachez quel agent a encore de la marge avant de lancer une grosse tâche.',
          items: [
            'Claude Code · Codex · Cursor',
            'GitHub Copilot · Gemini · Windsurf',
            'JetBrains AI · Cline · Kimi · +13',
          ],
          footer: 'Optionnel · Désactivé par défaut · 100 % local',
        },
        {
          label: 'PORTS & PROCESSUS',
          title: 'Ports & processus bloqués',
          description:
            'Oubliez lsof -i :3002 et voyez immédiatement le dossier qui occupe le port.',
          items: [
            'Recherche : 3002 · localhost:3002',
            'Affiche : PID · CWD · CPU% · RAM',
            'Action : quitter la tâche en 1 clic',
          ],
          footer: 'Directement depuis le popover ⌥⌘M',
        },
        {
          label: 'BATTERIE & THERMIQUE',
          title: 'Charge nocturne & chaleur',
          description: 'Préservez la batterie du MacBook sans installer de démon root.',
          items: [
            'Plafond : 80 % (macOS 26.4+)',
            'Capteurs SMC : temp. puce · RPM ventilateur',
            'Alertes : surchauffe et batterie faible',
          ],
          footer: 'Appliqué nativement après fermeture de Monny',
        },
      ],
      stepsTitle: 'Comment Monny reste rapide et privé',
      steps: [
        {
          step: '01 · INSTALLATION',
          title: 'Glisser dans Applications',
          description:
            'Installez via Homebrew ou DMG sur Apple Silicon (macOS 15+). Sans helper root ni connexion.',
        },
        {
          step: '02 · OPT-IN',
          title: 'Choisir vos outils IA',
          description:
            'Le suivi IA est désactivé par défaut. Activez uniquement les fournisseurs déjà connectés localement.',
        },
        {
          step: '03 · BARRE DES MENUS',
          title: 'Un coup d’œil avec ⌥⌘M',
          description:
            'Consultez quotas, comptes à rebours, ports ouverts et charge CPU sans changer de fenêtre.',
        },
        {
          step: '04 · SÉRÉNITÉ',
          title: 'Alertes utiles uniquement',
          description:
            'Soyez prévenu en cas de CPU emballé, pression mémoire, surchauffe ou limite atteinte - sans bruit.',
        },
      ],
      guarantees: [
        {
          title: 'Réutilise la session locale de chaque outil',
          description:
            'Monny lit les quotas localement via la CLI/session de chaque fournisseur. Aucun proxy tiers.',
        },
        {
          title: 'Aucun démon helper root',
          description:
            'Contrairement aux limiteurs classiques, Monny utilise l’API native macOS 26.4+ en utilisateur standard.',
        },
        {
          title: 'Zéro analytique ni compte',
          description:
            'Toute la télémétrie et l’historique 7 jours restent sur votre Mac. Rien n’est envoyé.',
        },
      ],
    },
    'port-pid-finder': {
      slug: 'port-pid-finder',
      path: '/guides/port-pid-finder/',
      breadcrumbLabel: 'Ports & processus',
      metaTitle: 'Trouver les ports ouverts et stopper un processus macOS sans lsof · Monny',
      metaDescription:
        'Recherchez les ports localhost actifs par numéro ou URL, inspectez PID et dossier de travail, puis arrêtez les serveurs bloqués en un clic depuis la barre des menus.',
      headline: 'Trouvez les ports ouverts et serveurs bloqués sans lsof.',
      subtitle:
        'Appuyez sur ⌥⌘M, tapez 3000 ou localhost:5432, vérifiez PID, dossier actif, CPU et RAM, et stoppez une tâche bloquée proprement sans commande terminal.',
      secondaryCtaLabel: 'À lire aussi : 22 quotas IA',
      secondaryCtaTo: '/guides/ai-coding-quotas/',
      cardsTitle: 'Tout le nécessaire quand un port est déjà occupé',
      cards: [
        {
          label: 'RECHERCHE INSTANTANÉE',
          title: 'Tapez un port ou une URL locale',
          description: 'Fini lsof -nP -iTCP:3000 -sTCP:LISTEN à chaque conflit de serveur.',
          items: [
            'Par port : 3000, 5173, 5432, 8080',
            'Par URL : localhost:3002',
            'Filtrer par nom de processus ou PID',
          ],
          footer: 'Recherche instantanée dans le popover ⌥⌘M',
        },
        {
          label: 'VRAI CONTEXTE',
          title: 'Voyez quel dépôt tient le port',
          description:
            'Sachez si le port 3000 vient d’un ancien worktree ou d’un agent en arrière-plan.',
          items: [
            'Chemin du dossier de travail (CWD)',
            'CPU% et mémoire en temps réel',
            'Processus parent et commande visibles',
          ],
          footer: 'Plus de doute entre plusieurs serveurs Node ou Go',
        },
        {
          label: 'ARRÊT PROPRE',
          title: 'Quittez les tâches bloquées simplement',
          description:
            'Arrêtez les serveurs orphelins ou watchers figés depuis la barre des menus.',
          items: [
            'Arrêt en un clic des tâches en écoute',
            'Repérez vite les boucles gourmandes en CPU',
            'Coexiste avec Docker et bases locales',
          ],
          footer: 'Zéro démon root · droits utilisateur standard macOS',
        },
      ],
      stepsTitle: 'De EADDRINUSE au port libre en quelques secondes',
      steps: [
        {
          step: '01 · OUVRIR',
          title: 'Appuyez sur ⌥⌘M partout',
          description:
            'Affichez le popover Monny au-dessus de votre éditeur ou terminal sans perdre le fil.',
        },
        {
          step: '02 · CHERCHER',
          title: 'Saisissez le numéro de port',
          description:
            'Entrez 3000, 3002 ou localhost:8080 pour isoler immédiatement le bon processus.',
        },
        {
          step: '03 · INSPECTER',
          title: 'Vérifiez PID et dossier projet',
          description:
            'Contrôlez le nom, le dossier de travail, le CPU et la RAM avant d’arrêter la tâche.',
        },
        {
          step: '04 · NETTOYER',
          title: 'Arrêtez et relancez proprement',
          description:
            'Quittez le processus bloqué en un clic et revenez directement dans votre terminal.',
        },
      ],
      guarantees: [
        {
          title: 'Lecture seule jusqu’à votre clic',
          description:
            'Monny ne ferme jamais un processus automatiquement. Vous vérifiez toujours le PID et le dossier.',
        },
        {
          title: 'Rapidité native Swift',
          description:
            'Développé en Swift 6 pour Apple Silicon (~5 Mo) avec une empreinte minime face aux apps Electron.',
        },
        {
          title: 'Complémentaire avec Hearth',
          description:
            'Monny suit la télémétrie macOS, ports, batterie et quotas IA ; Hearth gère runtimes, Docker, K8s et configs IA.',
        },
      ],
    },
  },
}
